require 'uri'
require 'net/http'

namespace :batch do
  desc "Sync temperatures if needed"
  task sync_temperatures: :environment do
    REDIS_LIST_KEY = 'space_temperatures'
    CONSUMER_DESTINATION_URL = 'http://localhost:3001/temperatures'
    CONSUMER_SUCCESS_MSG = 'temperature_received'
    redis = Redis.new(host: 'localhost')

    if redis.llen('space_temperatures') > 0 # can add a time check here too; ensure record wasn't just created
      unsynced_temperatures_array = redis.lrange(REDIS_LIST_KEY, 0, -1)
      serialized_temperatures_array = unsynced_temperatures_array.map do |str|
        temperature_obj = JSON.parse(str)
        temperature_celsius = (temperature_obj['temperature'] - 32) / 1.8
        {temperature: temperature_celsius, timestamp: temperature_obj['timestamp']}
      end


      serialized_unsynced_temperatures = {count: unsynced_temperatures_array.count, temperatures: serialized_temperatures_array}.to_json

      res = Net::HTTP.post_form(URI(CONSUMER_DESTINATION_URL), temperature_data: serialized_unsynced_temperatures)
      if res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body)['message'] == CONSUMER_SUCCESS_MSG
        redis.del(REDIS_LIST_KEY)
      end
    end
  end
end
