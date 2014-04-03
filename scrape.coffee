request = require 'request'
cheerio = require 'cheerio'
async   = require 'async'
open    = require 'open'
Quiche  = require 'quiche'

start     = 0
prices    = {}
done      = false
max       = Infinity
STOP_DATE = 'Mar 20'
PAGE_BY   = 100 # Pretty sure this is the only option on Craigslist anyway

getMax = (cb) ->
  url = "http://losangeles.craigslist.org/search/sss?s=0&catAbb=sss&query=coachella+weekend+2&excats=20-170"
  request url, (err, res, body) ->
    $ = cheerio.load(body)

    split = $('.pagenum').text().split(' ')
    max   = +split[split.length - 1]
    cb()

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
  url  = "http://losangeles.craigslist.org/search/sss?s=#{start}&catAbb=sss&query=coachella+weekend+2&excats=20-170"
  done = max - start < PAGE_BY
  
  console.log "#{start}/#{max}"
  
  request url, (err, res, body) ->
    return cb(err) if err

    $ = cheerio.load(body)
    
    for row in $('.row')
      postId   = row.attribs['data-pid']
      date     = $(row).children('.pl').children('.date').text()
      rawPrice = $(row).children('.l2').children('.price').text()
      
      continue unless rawPrice
      
      cleanPrice = rawPrice.match(/\d+$/)[0]
      done = date == STOP_DATE unless done
      
      prices[postId] = cleanPrice
    
    cb(null)

test = ->
  start += PAGE_BY
  return !done

getMax ->
  async.doWhilst fn, test, (err) ->
    processed = processResults()
    toChart(processed)
