
# Space App

Responsible for receiving sensor temperature data (fahrenheit) in space (via http request).

Persists data - and keeps track of data that has not been synced to a consumer on Earth.

Converts temperature data from fahrenheit to celsius; then serializes un-consumed data from space application to earth an Earth consumer.

Data is sent to earth as it is generated.

A cron job runs in the background every minute (can be adjusted).

The cron job is responsible for checking if any unsynced data exists - if such data exists a sync is attempted.

The cron job is responsible for retrying to sync unsynced data that may not have reached earth (as the application faces network blackouts - rogers or space)








## Ruby Version
3.0.0

## Rails Version
7.0.3


## Run Locally

```bash
  brew install redis

  # ensure redis server has started if it isn't already running
  brew services start redis

  # additional commands

  # stop redis
  brew services stop redis

  # restart redis
  brew services restart redis

  # add crontab to run rake task every minute
  exp. below
  * * * * * /bin/bash -l -c 'cd ~/Desktop/heat_up_above/space_app/ && /Users/josephb/.rvm/wrappers/ruby-3.0.0/rake batch:sync_temperatures'
```

Clone the project

```bash
  git clone git@github.com:JosephBianchi/space-app.git
```

Go to the project directory

```bash
  cd space-app
```

Install dependencies

```bash
  bundle install
```

Start the server

```bash
  rails server
```






## Usage/Examples

```bash
  # mock sensor data with http request:
  POST http://localhost:3000/temperatures

  JSON request body
  {
    "temperature": $temperature
  }

  # app should push temperature data onto a redis list - then attempt to sync to consumer.
  # if successful response from consumer - pop synced temperature data from redis list


```


## Authors

- Joseph Bianchi
