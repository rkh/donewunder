[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/rkh/donewunder)

Simple web app for posting completed Wunderlist items to iDoneThis.

## Wunderlist Application

You need to register your application with [Wunderlist](https://developer.wunderlist.com/applications). The Authorization Callback URL should be your App URL plus `/auth/wunderlist`.

## Development and Custom Deployment

Before anything else, run [`bundle install`](http://bundler.io/) in the project directory.

You can run the server by invoking `script/server`.

It expects the following environment variables to be set:

* `WUNDERLIST_CLIENT_ID` - Client ID of your Wunderlist application.
* `WUNDERLIST_CLIENT_SECRET` - Client ID of your Wunderlist application.
* `DATABASE_URL` - The database to use (you'll have to adjust the Gemfile if this is something other than postgres).

Optionally, you can also set the following env variables:

* `PORT` - The TCP port to run the web server on (default 5000).
* `RACK_ENV` - The environment to run under, should be `deployment` for a deployment and `development` for local development (default `development`). Note that in development mode, the server will only listen on `127.0.0.1` (localhost).
* `RACK_HANDLER` - Rack handler/server to be used (default `puma`).

You can also write these to a `.env` file you place in the project root, and `script/server` will automatically pick it up.

To set up the database structure, run `script/migrate`. This command is non-destructive.

Open up the page in your web browser.