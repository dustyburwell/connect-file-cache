request      = require 'request'
connect      = require 'connect'
connectCache = require '../lib/cache.js'
fs           = require 'fs'

cache = connectCache src: '../test_fixtures'
app = connect.createServer()
app.use cache.middleware
app.listen 3688

exports['Data with no extension is served properly'] = (test) ->
  cache.set 'i18n/klingon/success', 'Qapla!'

  request 'http://localhost:3688/i18n/klingon/success', (err, res, body) ->
    test.equals body, 'Qapla!'
    test.done()

exports['Files are cached after being served'] = (test) ->
  request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
    test.equals body, 'I am what I am.'
    test.equals res.headers['content-type'], 'text/plain'
    test.ok cache.get('/popeye-zen.txt')

    request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
      test.equals body, 'I am what I am.'
      test.equals res.headers['content-type'], 'text/plain'
      test.done()

exports['Cache is invalidated when file has changed'] = (test) ->
  request 'http://localhost:3688/raven-quoth.html', (err, res, body) ->
    test.equals body, 'Evermore'
    test.equals res.headers['content-type'], 'text/html'
    test.equals cache.get('/raven-quoth.html').toString('utf8'), 'Evermore'
    fs.writeFileSync '../test_fixtures/raven-quoth.html', 'Nevermore'

    request 'http://localhost:3688/raven-quoth.html', (err, res, body) ->
      test.equals body, 'Nevermore'
      test.equals cache.get('/raven-quoth.html').toString('utf8'), 'Nevermore'
      fs.writeFileSync '../test_fixtures/raven-quoth.html', 'Evermore'
      test.done()