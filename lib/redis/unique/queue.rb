require "redis"

class Redis
  module Unique
    class Queue
      attr_reader :name

      VERSION = "0.0.2"

      def initialize(name, redis_or_options = {})
        @name  = name
        @redis = if redis_or_options.kind_of? Redis
                   redis_or_options
                 elsif redis_or_options.kind_of? Hash
                   Redis.new redis_or_options
                 end
      end

      #Add an item to the queue. delay is in seconds.
      def push(data, delay=0)
        score = Time.now.to_f + delay
        @redis.zadd(name, score, data)
      end

      def front
        @redis.zrange(name, 0, 0).first
      end

      def pop
        begin
          success, result = attempt_atomic_pop
        end while !success
        result
      end

      def remove(data)
        @redis.zrem name, data
      end

      def size
        @redis.zcard name
      end

      private

      def attempt_atomic_pop
        min_score = 0
        max_score = Time.now.to_f

        result  = nil
        success = @redis.watch(name) do
          result = @redis.zrangebyscore(name, min_score, max_score, :with_scores => false, :limit => [0, 1]).first
          if result
            @redis.multi do |multi|
              multi.zrem name, result
            end
          end
        end

        [success, result]
      end
    end
  end
end
