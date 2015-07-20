# -*- encoding : utf-8 -*-
#Wrapper for redis connection
#============================
#Creates only one connection to redis per application in first time it needs to work with redis
module RedisModelExtension
  module Database
    DEFAULT_POOL_SIZE = 25
    DEFAULT_TIMEOUT = 5

    def self.config
      if File.exists?('config/redis_config.yml')
        cfg = YAML.load_file('config/redis_config.yml')[ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'].symbolize_keys
        self.redis_config = cfg
      else
        FileUtils.mkdir_p('config') unless File.exists?('config')
        FileUtils.cp(File.join(File.dirname(__FILE__),"../config/redis_config.yml.example"), 'config/redis_config.yml.example')
        raise ArgumentError, "Redis configuration file does not exists -> 'config/redis_config.yml', please provide it! I have created example file in config directory..."
      end
    end
    
    def self.redis_config= conf
      raise ArgumentError, "Argument must be hash {:host => '..', :port => 6379, :db => 0 }" unless conf.has_key?(:host) && conf.has_key?(:port) && conf.has_key?(:db)
      warn "Redis configuration doesn't include size and will be set to #{DEFAULT_POOL_SIZE}" unless conf.has_key?(:size)
      warn "Redis configuration doesn't include timeout and will be set to #{DEFAULT_TIMEOUT}" unless conf.has_key?(:timeout)
      @redis_config = conf
    end

    def self.redis= redis
      if redis.is_a?(Redis) #valid redis instance, create new pool
        @connection_pool = ConnectionPool::Wrapper.new { redis }
      elsif redis.nil? #remove connection_pool for changing connection or using in next call configs
        @connection_pool = nil
      else #else you assigned something wrong
        raise ArgumentError, "You have to assign Redis instance!"
      end
    end

    def self.redis &block
      unless @connection_pool
        cfg = @redis_config || self.config # fetch config or raises ArgumentError
        @connection_pool = ConnectionPool::Wrapper.new(
          size: cfg[:size] || DEFAULT_POOL_SIZE,
          timeout: cfg[:timeout] || DEFAULT_TIMEOUT
        ) { Redis.new(cfg.except(:size, :timeout)) }
      end

      block_given? ? @connection_pool.with(&block) : @connection_pool
    end

  end
end
