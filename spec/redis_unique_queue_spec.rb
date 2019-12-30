require 'spec_helper'

describe RedisUniqueQueue do
	let(:redis) { Redis.new }
	let(:name) { "some_queue" }
	let(:queue) { described_class.new(name, redis) }

	before do
		redis.flushall
	end

	context "instance methods" do
		describe '#push' do
			it 'should push items to the queue' do
				expect(queue.size).to eq(0)
				queue.push('a')
				queue.push('b')
				queue.push('c')
				expect(queue.size).to eq(3)
				expect(queue.all).to eq(%w(a b c))
			end
		end

		describe '#push_multi' do
			it 'should push multiple items to the queue' do
				expect(queue.size).to eq(0)
				queue.push_multi('a', 'b', 'c')
				expect(queue.size).to eq(3)
				expect(queue.all).to eq(%w(a b c))
			end
		end

		context do
			before do
				expect(queue.size).to eq(0)
				queue.push('a')
				queue.push('b')
				queue.push('c')
				expect(queue.size).to eq(3)
			end

			describe '#pop' do
				it 'should pop single items from the queue' do
					expect(queue.pop).to eq('a')
					expect(queue.size).to eq(2)

					expect(queue.pop).to eq('b')
					expect(queue.size).to eq(1)

					expect(queue.pop).to eq('c')
					expect(queue.size).to eq(0)
				end
			end

			describe '#pop_all' do
				it 'should pop all items from the queue' do
					expect(queue.pop_all).to eq(%w(a b c))
					expect(queue.size).to eq(0)
				end
			end

			describe '#pop_multi' do
				it 'should pop multiple items from the queue' do
					expect(queue.pop_multi(2)).to eq(%w(a b))
					expect(queue.size).to eq(1)
				end
			end

			describe '#front' do
				it 'shows the front of the queue' do
					expect(queue.front).to eq('a')
				end
			end

			describe '#back' do
				it 'shows the back of the queue' do
					expect(queue.back).to eq('c')
				end
			end

			describe '#remove' do
				it 'removes single items from the queue' do
					queue.remove('b')
					expect(queue.size).to eq(2)
					expect(queue.all).to eq(%w(a c))
				end
			end

			describe '#remove_item_by_index' do
				it 'removes single items by index' do
					queue.remove_item_by_index(1)
					expect(queue.size).to eq(2)
					expect(queue.all).to eq(%w(a c))
				end
			end

			describe '#size' do
				it 'returns the size of the queue' do
				  expect(queue.size).to eq(3)
				end
			end

			describe '#all' do
				it 'returns all of the items in the queue' do
				  expect(queue.all).to eq(%w(a b c))
				end
			end

			describe '#peek' do
				it 'allows you to peek at items in the queue without mutating the queue' do
				  expect(queue.peek(0,1)).to eq(%w(a))
					expect(queue.peek(1,1)).to eq(%w(b))
				  expect(queue.peek(2,1)).to eq(%w(c))
				  expect(queue.peek(3,1)).to eq([])

				  expect(queue.peek(0,2)).to eq(%w(a b))
				  expect(queue.peek(0,3)).to eq(%w(a b c))
				  expect(queue.peek(0,4)).to eq(%w(a b c))

				  expect(queue.peek(1,2)).to eq(%w(b c))
				  expect(queue.peek(1,3)).to eq(%w(b c))

					expect(queue.size).to eq(3)
					expect(queue.all).to eq(%w(a b c))
				end
			end

			describe '#include?' do
				it 'indicates if an item is in the queue or not' do
				  expect(queue.include?('a')).to be true
				  expect(queue.include?('A')).to be false

				  expect(queue.include?('b')).to be true
				  expect(queue.include?('B')).to be false

				  expect(queue.include?('c')).to be true
				  expect(queue.include?('C')).to be false
				end
			end

			describe '#clear' do
				it 'empties the queue' do
				  queue.clear
					expect(queue.size).to eq(0)
					expect(queue.all).to eq([])
				end
			end
		end
	end
end