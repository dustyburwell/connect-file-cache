# [connect-file-cache](http://github.com/TrevorBurnham/connect-file-cache)

fs      = require 'fs'
mime    = require 'mime'
path    = require 'path'
_       = require 'underscore'
{parse} = require 'url'

module.exports = (options = {}) -> new ConnectFileCache(options)

# options:
# * `src`: A dir containing files to be served directly (defaults to `null`)
# * `routePrefix`: Data will be served from this path (defaults to `/`)

class ConnectFileCache
  constructor: (@options, @map = {}) ->
    @options.src ?= null
    @options.routePrefix ?= '/'

  # Handle incoming requests
  middleware: (req, res, next) =>
    return next() unless req.method is 'GET'
    route = parse(req.url).pathname
    @loadFile route, =>
      if @map[route]
        @serveBuffer req, res, next, {route}
      else
        next()

  # If a file corresponding to the given route exists, load it in the cache
  loadFile: (route, callback) ->
    callback() unless @options.src
    filePath = path.join process.cwd(), @options.src, route
    fs.stat filePath, (err, stats) =>
      return callback() if err  # no matching file exists
      cacheTimestamp = @map[route]?.mtime
      if cacheTimestamp and (stats.mtime <= cacheTimestamp)
        callback filePath
      else
        fs.readFile filePath, (err, data) =>
          throw err if err
          @map[route] or= {}
          _.extend @map[route], {data}
          callback filePath

  serveBuffer: (req, res, next, {route}) ->
    {data, flags} = _.defaults @map[route], flags: {}
    res.setHeader 'Content-Type', flags.mime ? mime.lookup(route)
    res.setHeader 'Expires', FAR_FUTURE_EXPIRES if flags.expires is false
    if flags.attachment is true
      filename = path.basename(route)
      contentDisposition = 'attachment; filename="' + filename + '"'
      res.setHeader 'Content-Disposition', contentDisposition
    res.end data

  # Manage data directly, without physical files
  set: (routes, data, flags = {}) ->
    routes = [routes] unless routes instanceof Array
    data = new Buffer(data) unless data instanceof Buffer
    for route in routes
      @map[normalizeRoute route] = {data, flags: _.extend {}, flags}
    @

  remove: (routes) ->
    routes = [routes] unless routes instanceof Array
    delete @map[normalizeRoute route] for route in routes
    @

  get: (route) ->
    @map[normalizeRoute route].data

# constants
FAR_FUTURE_EXPIRES = "Wed, 01 Feb 2034 12:34:56 GMT"

# utility functions
normalizeRoute = (route) ->
  route = "/#{route}" unless route[0] is '/'
  route