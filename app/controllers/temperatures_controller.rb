require 'json'
require 'uri'
require 'net/http'

class TemperaturesController < ApplicationController
  REDIS_LIST_KEY = 'space_temperatures'
  CONSUMER_DESTINATION_URL = 'http://localhost:3001/temperatures'
  CONSUMER_SUCCESS_MSG = 'temperature_received'

  def create
    redis.rpush(REDIS_LIST_KEY, formatted_temperature_sensor_data)
    # perhaps would have looked into keyspace notifications here instead of
    # adding notification into create method
    # would have probably created more resiliance and used a DB; and
    # added to a redis stream after commit
    # this logic then could have been moved into a model
    notify_consumer
  end

  private
  def redis
    @redis ||= $redis
  end

  def formatted_temperature_sensor_data
    {temperature: temperature_param, timestamp: current_time}.to_json
  end

  def temperature_param
    params[:temperature]
  end

  def current_time
    Time.now
  end

  def notify_consumer
    begin
      res = Net::HTTP.post_form(URI(CONSUMER_DESTINATION_URL), temperature_data: serialized_unsynced_temperatures)
      redis.del(REDIS_LIST_KEY) if consumer_sync_success?(res)
    ensure
     # - could potentially create a job here based on a network failure
     # - chose to reduce complexity and run a cron job
     # - also if there is more than 1 temperature obj being sent - may be worth it
     # - to return an ID or time-stamp of a record that failed to sync - so we could add logic
     # - to unblock the queue (assuming all data is perfect at this point)
    end
  end

  def serialized_unsynced_temperatures
    {
      count: unsynced_temperatures_array.count,
      temperatures: unsynced_temperatures_array.map { |str| serialized_temperature(str) }
    }.to_json
  end

  def unsynced_temperatures_array
    @unsynced_temperatures_array ||= redis.lrange(REDIS_LIST_KEY, 0, -1)
  end

  def serialized_temperature(temperature_json)
    # - probably would have use a more scalable serialization technique
    # - in-case we need to change serializtion - or serialize for different consumers
    puts temperature_json.class
    puts temperature_json
    temperature_obj = JSON.parse(temperature_json)
    { temperature: farenheit_to_celsius(temperature_obj['temperature']), timestamp: temperature_obj['timestamp']}
  end

  def farenheit_to_celsius(temperature)
    (temperature - 32) / 1.8
  end

  def consumer_sync_success?(response)
    # this could be configurable fo different consumers
    response.is_a?(Net::HTTPSuccess) &&
      JSON.parse(response.body)['message'] == CONSUMER_SUCCESS_MSG
  end
end
