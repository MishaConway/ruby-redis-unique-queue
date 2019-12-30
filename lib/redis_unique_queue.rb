require "redis"

class RedisUniqueQueue
	attr_reader :name

	VERSION = "2.0"

	class InvalidNameException < StandardError; end;
	class InvalidRedisConfigException < StandardError; end;

	def initialize(name, redis_or_options = {}, more_options = {})
		name = name.to_s if name.kind_of? Symbol

		raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
		@name = name
		@redis = if redis_or_options.kind_of?(Redis)
			         redis_or_options
			       elsif redis_or_options.kind_of? Hash
				       ::Redis.new redis_or_options
			       elsif defined?(ActiveSupport::Cache::RedisStore) && redis_or_options.kind_of?(ActiveSupport::Cache::RedisStore)
				       @pooled = redis_or_options.data.kind_of?(ConnectionPool)
				       redis_or_options.data
			       elsif defined?(ConnectionPool) && redis_or_options.kind_of?(ConnectionPool)
				       @pooled = true
				       redis_or_options
			       else
				       raise InvalidRedisConfigException.new
		         end

		if more_options.kind_of?(Hash) && more_options[:expire]
			expire more_options[:expire]
		end
	end

	def push data
		[block_on_atomic_attempt { attempt_atomic_push_multi(data) }].flatten.first
	end

	def push_multi *values
		if values.size > 0
			block_on_atomic_attempt { attempt_atomic_push_multi(*values) }
		end
	end

	def pop
		block_on_atomic_attempt { attempt_atomic_pop }
	end

	def pop_all
		block_on_atomic_attempt { attempt_atomic_pop_all }
	end

	def pop_multi amount
		block_on_atomic_attempt { attempt_atomic_pop_multi amount }
	end

	def front
		with { |redis| redis.zrange(name, 0, 0).first }
	end

	def back
		with { |redis| redis.zrevrange(name, 0, 0).first }
	end

	def remove data
		with { |redis| redis.zrem name, data }
	end

	def remove_item_by_index index
		with { |redis| redis.zremrangebyrank name, index, index }
	end

	def size
		with { |redis| redis.zcard name }
	end

	def all
		peek 0, size
	end

	def peek index, amount = 1
		with { |redis| redis.zrange name, index, index + amount - 1 }
	end

	def include? data
		!with { |redis| redis.zscore(name, data).nil? }
	end

	def clear
		with { |redis| redis.del name }
		[]
	end

	def expire seconds
		with { |redis| redis.expire name, seconds }
	end

	private

	def max_score
		with { |redis| redis.zscore name, back }
	end

	def attempt_atomic_push_multi *values
		with do |redis|
			success = redis.watch(name) do
				score = [Time.now.to_f, max_score].compact.max
				values = values.first if 1 == values.size && values.first.kind_of?(Array)
				scored_values = []
				values.each_with_index do |value, i|
					scored_values << [score + i, value]
				end
				redis.multi do |multi|
					multi.zadd name, scored_values
				end
			end

			[success, values]
		end
	end

	def attempt_atomic_pop_multi amount
		attempt_atomic_read_write lambda { peek 0, amount }, lambda { |multi, read_result| multi.zremrangebyrank name, 0, amount - 1 }
	end

	def attempt_atomic_pop_all
		attempt_atomic_read_write lambda { all }, lambda { |multi, read_result| multi.del name }
	end

	def attempt_atomic_pop
		read = lambda do
			with{|redis| redis.zrangebyscore(name, 0, max_score, :with_scores => false, :limit => [0, 1]).first}
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
		result = nil
		success = with do |redis|
			redis.watch(name) do
				result = read_op.call
				if result
					redis.multi do |multi|
						write_op.call multi, result
					end
				end
			end
		end

		[success, result]
	end

	private

	def with(&block)
		if pooled?
			@redis.with(&block)
		else
			block.call(@redis)
		end
	end

	def pooled?
		!!@pooled
	end
end

