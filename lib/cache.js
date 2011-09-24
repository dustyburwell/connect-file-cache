(function() {
  var ConnectFileCache, FAR_FUTURE_EXPIRES, fs, mime, normalizeRoute, parse, path, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require('fs');
  mime = require('mime');
  path = require('path');
  _ = require('underscore');
  parse = require('url').parse;
  module.exports = function(options) {
    if (options == null) {
      options = {};
    }
    return new ConnectFileCache(options);
  };
  ConnectFileCache = (function() {
    function ConnectFileCache(options, map) {
      var _base, _base2, _ref, _ref2;
      this.options = options;
      this.map = map != null ? map : {};
      this.middleware = __bind(this.middleware, this);
      if ((_ref = (_base = this.options).src) == null) {
        _base.src = null;
      }
      if ((_ref2 = (_base2 = this.options).routePrefix) == null) {
        _base2.routePrefix = '/';
      }
    }
    ConnectFileCache.prototype.middleware = function(req, res, next) {
      var route;
      if (req.method !== 'GET') {
        return next();
      }
      route = parse(req.url).pathname;
      return this.loadFile(route, __bind(function() {
        if (this.map[route]) {
          return this.serveBuffer(req, res, next, {
            route: route
          });
        } else {
          return next();
        }
      }, this));
    };
    ConnectFileCache.prototype.loadFile = function(route, callback) {
      var filePath;
      if (!this.options.src) {
        callback();
      }
      filePath = path.join(process.cwd(), this.options.src, route);
      return fs.stat(filePath, __bind(function(err, stats) {
        var cacheTimestamp, _ref;
        if (err) {
          return callback();
        }
        cacheTimestamp = (_ref = this.map[route]) != null ? _ref.mtime : void 0;
        if (cacheTimestamp && (stats.mtime <= cacheTimestamp)) {
          return callback(filePath);
        } else {
          return fs.readFile(filePath, __bind(function(err, data) {
            var _base;
            if (err) {
              throw err;
            }
            (_base = this.map)[route] || (_base[route] = {});
            _.extend(this.map[route], {
              data: data
            });
            return callback(filePath);
          }, this));
        }
      }, this));
    };
    ConnectFileCache.prototype.serveBuffer = function(req, res, next, _arg) {
      var contentDisposition, data, filename, flags, route, _ref, _ref2;
      route = _arg.route;
      _ref = _.defaults(this.map[route], {
        flags: {}
      }), data = _ref.data, flags = _ref.flags;
      res.setHeader('Content-Type', (_ref2 = flags.mime) != null ? _ref2 : mime.lookup(route));
      if (flags.expires === false) {
        res.setHeader('Expires', FAR_FUTURE_EXPIRES);
      }
      if (flags.attachment === true) {
        filename = path.basename(route);
        contentDisposition = 'attachment; filename="' + filename + '"';
        res.setHeader('Content-Disposition', contentDisposition);
      }
      return res.end(data);
    };
    ConnectFileCache.prototype.set = function(routes, data, flags) {
      var route, _i, _len;
      if (flags == null) {
        flags = {};
      }
      if (!(routes instanceof Array)) {
        routes = [routes];
      }
      if (!(data instanceof Buffer)) {
        data = new Buffer(data);
      }
      for (_i = 0, _len = routes.length; _i < _len; _i++) {
        route = routes[_i];
        this.map[normalizeRoute(route)] = {
          data: data,
          flags: _.extend({}, flags)
        };
      }
      return this;
    };
    ConnectFileCache.prototype.remove = function(routes) {
      var route, _i, _len;
      if (!(routes instanceof Array)) {
        routes = [routes];
      }
      for (_i = 0, _len = routes.length; _i < _len; _i++) {
        route = routes[_i];
        delete this.map[normalizeRoute(route)];
      }
      return this;
    };
    ConnectFileCache.prototype.get = function(route) {
      return this.map[normalizeRoute(route)].data;
    };
    return ConnectFileCache;
  })();
  FAR_FUTURE_EXPIRES = "Wed, 01 Feb 2034 12:34:56 GMT";
  normalizeRoute = function(route) {
    if (route[0] !== '/') {
      route = "/" + route;
    }
    return route;
  };
}).call(this);
