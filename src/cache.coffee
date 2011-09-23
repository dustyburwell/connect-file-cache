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
    console.log "#{route} = route"
    if @map[route]
      @serveBuffer req, res, next, route
    else
      filePath = path.join process.cwd(), @options.src, route
      self = this
      fs.stat filePath, (err, stats) ->
        return next() if err
        fs.readFile filePath, (err, data) ->
          self.map[route] = {data, flags: {}}
          self.serveBuffer req, res, next, route

  serveBuffer: (req, res, next, route) ->
    {data, flags} = @map[route]
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