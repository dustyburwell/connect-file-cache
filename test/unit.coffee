connectCache = require '../lib/cache'
cache = connectCache()

exports['add converts strings to buffers'] = (test) ->
  cache.set 'a', 'str1'
  cache.set 'b', new Buffer('str2')
  test.ok cache.get('a') instanceof Buffer
  test.equal cache.get('a').toString('utf8'), 'str1'
  test.ok cache.get('b') instanceof Buffer
  test.equal cache.get('b').toString('utf8'), 'str2'
  test.done()