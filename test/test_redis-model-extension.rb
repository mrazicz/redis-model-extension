# -*- encoding : utf-8 -*-
require 'helper'
class RedisModelTest < Test::Unit::TestCase
  context "RedisModel" do
    setup do
      Database.redis.flushdb
      
      class TestRedisModel
        REDIS_MODEL_CONF = {
           :fields => { 
             :integer => :to_i,
             :boolean => :to_bool,
             :string => :to_s,
             :symbol => :to_sym,
            }, 
            :required => [:integer, :string],
            :redis_key => [:string],
            :redis_aliases => {
              :token => [:symbol]
            }
         }
         include RedisModel
         initialize_redis_model_methods REDIS_MODEL_CONF
      end
      @args = {:integer => 12345, :string => "foo", :symbol => :bar, :boolean => true}
      @test_model = TestRedisModel.new(@args)
      @test_model_partial = TestRedisModel.new(:integer => 12345, :string => "foo")
    end 
    
    context "define methods" do
      should "be accessible" do
        assert @test_model.respond_to?(:integer)
        assert @test_model.respond_to?(:boolean)
        assert @test_model.respond_to?(:string)
        assert @test_model.respond_to?(:symbol)
      end
      
      should "get valid arguments" do
        assert_equal @test_model.integer, 12345
        assert_equal @test_model.string, "foo"
        assert_equal @test_model.symbol, :bar
        assert_equal @test_model.boolean, true
      end
      
      should "return valid exists?" do
        assert_equal @test_model.integer?, true
        assert_equal @test_model.string?, true
        assert_equal @test_model.symbol?, true
        assert_equal @test_model.boolean?, true
        
        assert_equal @test_model_partial.integer?, true
        assert_equal @test_model_partial.string?, true
        assert_equal @test_model_partial.symbol?, false
        assert_equal @test_model_partial.boolean?, false
      end
      
      should "be assign new values" do
        @test_model.integer = 54321
        @test_model.string = "bar"
        @test_model.symbol = :foo
        @test_model.boolean = false
        assert_equal @test_model.integer, 54321
        assert_equal @test_model.string, "bar"
        assert_equal @test_model.symbol, :foo
        assert_equal @test_model.boolean, false
      end
    end
         
    context "redis key" do
      should "generate right key" do
        assert_equal @test_model.redis_key, "redismodeltest::testredismodel:foo"
        assert_equal TestRedisModel.generate_key(@args), "redismodeltest::testredismodel:foo"
      end  
      should "generate right key alias" do
        assert_equal @test_model.redis_alias_key(:token), "redismodeltest::testredismodel:token:bar"
        assert_equal TestRedisModel.generate_alias_key(:token, @args), "redismodeltest::testredismodel:token:bar"
      end  
    end
    
    context "after initialize" do 
      should "clear input arguments" do
        test_model = TestRedisModel.new(@args.merge({:foor => :bar, :not_in_fields => "foo"}))
        assert_same_elements test_model.args, @args
      end
    end
    
    context "validation" do
      should "not raise exeption on invalid initialize" do
        assert_nothing_raised { TestRedisModel.new() }
      end

      should "raise exeption on save" do
        test_model = TestRedisModel.new()
        assert_raises ArgumentError do
          test_model.save
        end
      end
    end
    
    context "saving" do
      setup do
        @test_model.save
      end
      
      should "have same elements after get" do
        @getted_model = TestRedisModel.get(@args)
        assert_equal @getted_model.integer, @test_model.integer
        assert_equal @getted_model.string, @test_model.string
        assert_equal @getted_model.symbol, @test_model.symbol
        assert_equal @getted_model.boolean, @test_model.boolean
      end
      
      should "be getted by alias" do
        @getted_model = TestRedisModel.get_by_alias(:token ,@args)
        assert_equal @getted_model.integer, @test_model.integer
        assert_equal @getted_model.string, @test_model.string
        assert_equal @getted_model.symbol, @test_model.symbol
        assert_equal @getted_model.boolean, @test_model.boolean
      end
    end
    
  end
end