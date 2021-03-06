# -*- encoding : utf-8 -*-
module RedisModelExtension
  
  # == Class Redis Key
  # generators of redis keys
  # used for creating keys for search and save of models & aliases
  # 
  module ClassRedisKey

    # Generates redis key for storing object
    # * will produce something like: your_class:key:field_value1:field_value2... 
    # (depending on your redis_key setting)
    def generate_key args = {}, key = "key"
      #normalize input hash of arguments
      args = HashWithIndifferentAccess.new(args)

      out = "#{self.name.to_s.underscore.to_sym}:#{key}"
      redis_key_config.each do |key|
        out += add_item_to_redis_key args, key
      end
      out
    end


    # Generates redis key for storing indexes for dynamic aliases
    # will produce something like: your_class:dynamic:name_of_your_dynami_alias:field_value2:field_value1... 
    # (field values are sorted by fields order)
    # * dynamic_alias_name (Symbol) - name of your dynamic alias
    # * args (Hash) - arguments of your model
    # * field_order (Array of symbols) - order of fields (ex. [:field2, :field1]) 
    # * field_args (Hash) - hash of values for aliasing (ex. {:field1 => "field_value1", :field2 => "field_value2"})
    def generate_alias_key alias_name, args = {}
      #check if asked dynamic alias exists
      raise ArgumentError, "Unknown dynamic alias: '#{alias_name}', use: #{redis_alias_config.keys.join(", ")} " unless redis_alias_config.has_key?(alias_name.to_sym)

      #normalize input hash of arguments
      args = HashWithIndifferentAccess.new(args)

      # prepare class name + dynamic + alias name
      out = "#{self.name.to_s.underscore.to_sym}:alias:#{alias_name}"

      #get config 
      config = redis_alias_config[alias_name.to_sym]

      # use all specified keys
      config[:main_fields].each do |key|
        out += add_item_to_redis_key args, key
      end

      #is alias dynamic?
      if config[:order_field] && config[:args_field]
        #check if input arguments has order field
        if args.has_key?(config[:order_field]) && args[config[:order_field]] && args.has_key?(config[:args_field]) && args[config[:args_field]]
          #use filed order from defined field in args
          args[config[:order_field]].each do |key|
            out += add_item_to_redis_key args[config[:args_field]], key
          end
        else 
          # use global search
          out += ":*"
        end
      end

      out    
    end

    # Check if key by arguments exists in db
    def exists? args = {}
      RedisModelExtension::Database.redis {|r| r.exists(self.name.constantize.generate_key(args)) }
    end

    #Check if key by alias name and arguments exists in db
    def alias_exists? alias_name, args = {}
      RedisModelExtension::Database.redis {|r| r.exists(self.name.constantize.generate_alias_key(alias_name, args)) }
    end

    private

    # return one item of redis key (will decide to input value or to add * for search)
    def add_item_to_redis_key args, key
      if args.has_key?(key) && !args[key].nil?
        key = ":#{args[key]}"
        key = key.mb_chars.downcase if redis_key_normalize_conf.include?(:downcase)
        key = ActiveSupport::Inflector::transliterate(key) if redis_key_normalize_conf.include?(:transliterate)
        key 
      else
        ":*"
      end
    end

  end
  
  # == Redis Key
  # aliases for instance to class generators of redis keys
  # 
  module RedisKey

    # get redis key for instance
    def redis_key
      self.class.generate_key(to_arg)
    end
    
    # get redis key for instance alias
    def redis_alias_key alias_name 
      self.class.generate_alias_key(alias_name, to_arg)
    end
  
    # pointer to exists?
    def exists?
      self.class.exists? to_arg
    end

    # pointer to alias_exists?
    def alias_exists? alias_name
      self.class.alias_exists? alias_name, to_arg
    end

  end
end
