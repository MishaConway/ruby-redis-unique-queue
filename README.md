# Redis::Unique::Queue

A unique FIFO queue with atomic operations built on top of Redis. Useful if you want to enqueue data without worrying about it existing multiple times in the queue.


## Installation

Add this line to your application's Gemfile:

    gem 'redis-unique-queue'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-unique-queue

## Getting started

You can instantiate a named queue using your default Redis configuration.

```ruby
q = Redis::Unique::Queue.new 'jobs'
```

Or you can pass in your own instance of the Redis class.

```ruby
q = Redis::Unique::Queue.new 'jobs', Redis.new(:host => "10.0.1.1", :port => 6380, :db => 15)
```

A third option is to instead pass your Redis configurations.

```ruby
q = Redis::Unique::Queue.new 'jobs', :host => "10.0.1.1", :port => 6380, :db => 15
```

## Using the queue

You can push data to the queue.

```ruby
q.push "hello"
q.push "world"
q.push "hello" # the item 'hello' will only exist once in the queue since it is unique
```

You can pop data from the queue.

```ruby
result = q.pop
```

You can get the size of the queue.

```ruby
q.size
```

You can read the first item in the queue.

```ruby
q.front
```

You can see if an item exists in the queue.

```ruby
q.include? "hello"
```

You can remove an arbitrary item from the queue. Note that it doesn't have to be the first item.

```ruby
q.remove "world"
```

You can get all items in the queue.

```ruby
q.all
```

You can also peek into arbitrary ranges in the queue.

```ruby
q.peek 1 #read the item at index 1
q.peek 23 #read the item at index 23
q.peek 10, 5 #peek at five items starting at index 10
```



## Contributing

1. Fork it ( http://github.com/<my-github-username>/redis-unique-queue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
