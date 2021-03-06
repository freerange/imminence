require "sidekiq"

redis_config = YAML.load_file(Rails.root.join("config", "redis.yml"))[Rails.env].symbolize_keys

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
