# Derived class must implement to_vec, indicating how the builder
# will be transformed into a vector.  Additionally, the derived
# class must register itself by calling register with a symbol.
# Builds Vectors
class VectorBuilder
	include Enumerable

	@@builders = {}

	# Creates a vector builder of the given type and initializes with block
	def VectorBuilder.create(type, *args, &block)
		@@builders[type].send(:new, *args, &block)
	end

	# Derived classes call this to register their types so that they can be built through create
	def self.register(type)
		@@builders[type] = self
	end

	private_class_method :new

	# Create VectorBuilder of given size
	def initialize(size)
		@size = size
		@values = Hash.new(0)
		yield self if block_given?
	end

	# Create VectorBuilder that is a copy of other
	def initialize_copy(other)
		@size = other.size
		@values = other.values.dup
	end

	protected
	attr_reader :values

	public
	attr_reader :size

	alias length size

	# Access element at index i
	def [](i)
		@values[i]
	end

	# Set element at index i
	def []=(i, x)
		@values[i] = x if x != 0 && i >= 0 && i < size
	end
end
