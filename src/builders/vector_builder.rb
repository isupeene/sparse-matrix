# Derived class must implement to_vec, indicating how the builder
# will be transformed into a vector.  Additionally, the derived
# class must register itself by calling register with a symbol.
class VectorBuilder
	include Enumerable

	@@builders = {}

	def VectorBuilder.create(type, *args, &block)
		@@builders[type].send(:new, *args, &block)
	end

	def self.register(type)
		@@builders[type] = self
	end

	private_class_method :new

	def initialize(size)
		@size = size
		@values = Hash.new(0)
		yield self if block_given?
	end

	def initialize_copy(other)
		@size = other.size
		@values = other.values.dup
	end

	protected
	attr_reader :values

	public
	attr_reader :size

	alias length size

	def [](i)
		@values[i]
	end

	def []=(i, x)
		@values[i] = x if x != 0 && i >= 0 && i < size
	end
end
