require "redis"

class Redis
  module Unique
    class Queue
      attr_reader :name

      VERSION = "1.0.2"

      class InvalidNameException < StandardError; end;
      class InvalidRedisConfigException < StandardError; end;

      def initialize(name, redis_or_options = {})
        name = name.to_s if name.kind_of? Symbol
        
        raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
        @name  = name
        @redis = if redis_or_options.kind_of? Redis
                   redis_or_options
                 elsif redis_or_options.kind_of? Hash
                   Redis.new redis_or_options
                 else
                  raise InvalidRedisConfigException.new
                 end
      end

      def push data
        score = Time.now.to_f
        @redis.zadd(name, score, data)
      end

      def push_multi *values
        if values.size > 0
          score = Time.now.to_f

          values = values.first if 1 == values.size && values.first.kind_of?(Array)
          scored_values = []
          values.each_with_index do |value, i|
            scored_values << [score + i, value]
          end

          @redis.zadd name, scored_values
        end
      end

      def pop
        block_on_atomic_attempt{ attempt_atomic_pop }
      end

      def pop_all
        block_on_atomic_attempt{ attempt_atomic_pop_all }
      end

      def pop_multi amount
        block_on_atomic_attempt{ attempt_atomic_pop_multi amount }
      end

      def front
        @redis.zrange(name, 0, 0).first
      end

      def back
        @redis.zrevrange(name, 0, 0).first
      end

      def remove data
        @redis.zrem name, data
      end

      def remove_item_by_index index
        @redis.zremrangebyrank name, index, index
      end

      def size
        @redis.zcard name
      end

      def all
        peek 0, size
      end

      def peek index, amount=1
        @redis.zrange name, index, index + amount - 1
      end

      def include? data
        !@redis.zscore(name, data).nil?
      end

      def clear
        @redis.del name
        []
      end

      def expire seconds
        @redis.expire name, seconds
      end

      private
      
      def attempt_atomic_pop_multi amount
        attempt_atomic_read_write lambda{ peek 0, amount }, lambda{  |multi, read_result| multi.zremrangebyrank name, 0, amount - 1 }
      end

      def attempt_atomic_pop_all
        attempt_atomic_read_write lambda{ all }, lambda{ |multi, read_result| multi.del name}
      end

      def attempt_atomic_pop
        min_score = 0
        max_score = Time.now.to_f

        read = lambda do
          @redis.zrangebyscore(name, min_score, max_score, :with_scores => false, :limit => [0, 1]).first
        end

        write = lambda do |multi, read_result|
          multi.zrem name, read_result
        end

        attempt_atomic_read_write read, write
      end

      def block_on_atomic_attempt
        begin
          success, result = yield
        end while !success && result
        result
      end

      def attempt_atomic_read_write read_op, write_op

        result  = nil
        success = @redis.watch(name) do
          result = read_op.call
          if result
            @redis.multi do |multi|
              write_op.call multi, result
            end
          end
        end

        [success, result]
      end
    end
  end
end
