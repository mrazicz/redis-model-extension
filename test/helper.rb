require 'simplecov'
SimpleCov.start do 
  add_filter "/test/"
  add_filter "/config/"
  add_filter "database"
  
  add_group 'Lib', 'lib/'
end

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'
require 'turn'
require 'shoulda-context'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'redis-model-extension'


class TestRedisModel
  include RedisModelExtension
  redis_field :integer, :integer
  redis_field :boolean, :bool
  redis_field :string,  :string
  redis_field :symbol,  :symbol, :default
  redis_field :array,   :array
  redis_field :hash,    :hash
  redis_field :time,    :time
  redis_field :date,    :date
  redis_field :float,   :float
  
  redis_validate :integer, :string 
  redis_key :string

  redis_alias :token, [:symbol]

end
