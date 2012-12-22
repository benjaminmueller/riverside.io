###
Module dependencies.
###
express = require("express")
members = require("./members.json")
routes = require("./routes")
http = require("http")
path = require("path")
MailChimpAPI = require('mailchimp').MailChimpAPI;

apiKey = process.env.MAILCHIMPAPIKEY;
LISTID = null
#try mailchimp api

try
  api = new MailChimpAPI(apiKey,
    version: "1.3"
    secure: false
  )
catch error
  console.log error.message

#get mailinglist id

api.lists (err, res) ->
  if err
    console.log err
  else
    # we only have one list for time being
    console.log res.data[0].id
    LISTID = res.data[0].id



app = express()

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))
  app.use require('connect-assets')()

app.configure "development", ->
  app.use express.errorHandler()

app.locals.members = members 

app.get "/", routes.index

app.get "/locations", routes.locations

app.post "/subscribe", (req, res) ->
  email = req.body.email
  valid = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.test email
  redirect = 'http://riverside.us5.list-manage2.com/subscribe?u=0b634d613f02dd256ad0d7317&id=27ea75d96b&MERGE0=' + email

  if(valid)

    if(api and LISTID)

      api.listSubscribe
        apiKey        : apiKey
        id            : LISTID #add list id here
        email_address : email, 
        (err, _res) ->
          if err
            res.json 
              success : false
              error   : err
              redirect : redirect
          else

            console.log _res

            res.json 
              success    : _res
    else

      res.json
        success: false
        redirect : redirect

  else

    res.json
      success : false
      error : ['email']

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
