require "redis"

class Redis
  module Unique
    class Queue
      attr_reader :name

      VERSION = "0.0.7"

      def initialize(name, redis_or_options = {})
        @name  = name
        @redis = if redis_or_options.kind_of? Redis
                   redis_or_options
                 elsif redis_or_options.kind_of? Hash
                   Redis.new redis_or_options
                 end
      end

      #Add an item to the queue. delay is in seconds.
      def push data, delay=0
        score = Time.now.to_f + delay
        @redis.zadd(name, score, data)
      end

      def pop
        begin
          success, result = attempt_atomic_pop
        end while !success && result
        result
      end

      def pop_all
        begin
          success, result = attempt_atomic_pop_all
        end while !success && result
        result
      end

      def front
        @redis.zrange(name, 0, 0).first
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
      end

      def expire seconds
        @redis.expire name, seconds
      end

      private

      def attempt_atomic_pop_all
        result  = nil
        success = @redis.watch(name) do
          result = all
          if result
            @redis.multi do |multi|
              multi.del name
            end
          end
        end

        [success, result]
      end

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
