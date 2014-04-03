request = require 'request'
cheerio = require 'cheerio'
async   = require 'async'
Quiche  = require 'quiche'
open    = require 'open'

start     = 0
prices    = {}
done      = false
STOP_DATE = 'Mar 26'

toChart = (data) ->
  labels = []
  for row, i in data
    if i%4
      labels.push('')
    else
      labels.push(row.price)
  
  bar = new Quiche('bar')
  bar.setWidth(900)
  bar.setHeight(200)
  bar.setTitle('COACHELLA')
  bar.setBarWidth(2)
  bar.setBarSpacing(4)
  bar.setAutoScaling()
  bar.addData(data.map((row) -> row.count))
  bar.addAxisLabels('x', labels)

  imageUrl = bar.getUrl(true)
  open(imageUrl)

processResults = ->
  counts = {}
  ret    = []
  for pid, price of prices
    counts[price] ?= 0
    counts[price]++

  for price, count of counts
    ret.push({ price, count })

  ret.sort (a, b) -> a.price - b.price
  return ret

fn = (cb) ->
  url = "http://losangeles.craigslist.org/search/sss?s=#{start}&catAbb=sss&query=coachella+weekend+2&excats=20-170"
  
  request url, (err, res, body) ->
    return cb(err) if err

    $ = cheerio.load(body)
    
    for row in $('.row')
      postId   = row.attribs['data-pid']
      date     = $(row).children('.pl').children('.date').text()
      rawPrice = $(row).children('.l2').children('.price').text()
      
      continue unless rawPrice
      
      cleanPrice = rawPrice.match(/\d+$/)[0]
      done = date == STOP_DATE
      
      prices[postId] = cleanPrice
     
    cb(null)

test = ->
  console.log 'Done?', done
  start += 100
  return !done

async.doWhilst fn, test, (err) ->
  processed = processResults()
  toChart(processed)
