request      = require 'request'
connect      = require 'connect'
connectCache = require '../lib/cache.js'

cache = connectCache src: 'fixtures'
app = connect.createServer()
app.use cache.middleware
app.listen 3688

exports['Data with no extension is served properly'] = (test) ->
  cache.set 'i18n/klingon/success', 'Qapla!'

  request 'http://localhost:3688/i18n/klingon/success', (err, res, body) ->
    test.ok !err
    test.equals body, 'Qapla!'
    test.done()

exports['Files are cached after being served'] = (test) ->
  cache.set 'i18n/klingon/success', 'Qapla!'

  request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
    test.ok !err
    test.equals body, 'I am what I am.'
    test.equals res.headers['content-type'], 'text/plain'
    test.ok cache.get('/popeye-zen.txt')
    test.done()