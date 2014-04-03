request = require 'request'
cheerio = require 'cheerio'
async   = require 'async'

start  = 0
prices = {}
done   = false

processResults = ->
  counts = {}
  ret    = []
  for pid, price of prices
    counts[price] ?= 0
    counts[price]++

  # Sort
  for price, count of counts
    ret.push({ price, count })

  ret.sort (a, b) -> a.price - b.price
  console.log ret

fn = (cb) ->
  url = "http://losangeles.craigslist.org/search/sss?s=#{start}&catAbb=sss&query=coachella%20weekend%202"
  
  request url, (err, res, body) ->
    return cb(err) if err

    $ = cheerio.load(body)
    
    for row in $('.row')
      postId   = row.attribs['data-pid']
      date     = $(row).children('.pl').children('.date').text()
      rawPrice = $(row).children('.l2').children('.price').text()
      
      continue unless rawPrice
      
      cleanPrice = rawPrice.match(/\d+$/)[0]
      
      done = date == 'Apr  1'
      
      prices[postId] = cleanPrice
     
    cb(null)

test = ->
  console.log 'test done', done
  start += 100
  return !done

async.doWhilst fn, test, (err) ->
  processResults()
