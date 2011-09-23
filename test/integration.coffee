request      = require 'request'
connect      = require 'connect'
connectCache = require '../lib/cache.js'

cache = connectCache()
app = connect.createServer()
app.use cache.middleware
app.listen 3688

exports['Data with no extension is served properly'] = (test) ->
  cache.set 'i18n/klingon/success', 'Qapla!'

  request 'http://localhost:3688/i18n/klingon/success', (err, res, body) ->
    test.ok !err, 'No error'
    test.equals body, 'Qapla!'
    test.done()