# Heroku Connector

This web service provides a means to connect DNSimple domains with Heroku applications.

## Running Locally

To start the Heroku Connector app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Running on Heroku

- Create the Heroku application
- In the top-level repo directory run:
  - `heroku git:remote -a appname` where appname is the Heroku app name
  - `heroku buildpacks:set https://github.com/HashNuke/heroku-buildpack-elixir.git`
  - `heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git`
  - `heroku addons:create heroku-postgresql:hobby-dev`
- Next, set up environment variables
  - `heroku config:set APP_HOSTNAME=appname.herokuapp.com` where appname is the Heroku app name
  - `heroku config:set POOL_SIZE=18` adjust if you use a different postgres tier
  - `mix phoenix.gen.secret` and use the result in `heroku config:set SECRET_KEY_BASE="generated-secret"`
  - Add application to DNSimple
    - `heroku config:set DNSIMPLE_CLIENT_ID=id`
    - `heroku config:set DNSIMPLE_CLIENT_SECRET=secret`
  - Add application to Heroku
    - `heroku config:set HEROKU_CLIENT_ID=id`
    - `heroku config:set HEROKU_CLIENT_SECRET=secret`
