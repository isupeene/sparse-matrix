require 'matrix'

require_relative '../overload_table'
require_relative '../scalar'
require_relative '../contracts/matrix_contract'
require_relative '../contracts/vector_contract'
require_relative '../builders/vector_builder'
require_relative '../builders/sparse_vector_builder'
require_relative '../builders/matrix_builder'
require_relative '../builders/sparse_matrix_builder'
require_relative '../builders/complete_matrix_builder'

# Implementation of a Sparse Vector. Decorated through SparseVector class.
class SparseVectorImpl
	include Enumerable
	include Matrix::CoercionHelper

	##################
	# Initialization #
	##################

	# Initialize vector from builder specs
	def initialize(builder)
		@size = builder.size
		@indices, @values = builder.transpose
	end

	# Initialize vector that is a copy of other
	def initialize_copy(other)
		@size = other.size
		@indices = other.indices.dup
		@values = other.values.dup
	end

	##########
	# Access #
	##########

	protected
	attr_reader :size
	attr_reader :indices
	attr_reader :values

	# Finds index inside compressed vector of the index i requested
	private
	def select_index(i)
		# NOTE: Ruby 2.x provides bsearch, implemented in C,
		# which is more efficient than index.  Unfortunately,
		# a ruby implementation of bsearch will not be more
		# efficient than the built-in index method - which
		# is implemented in C - for most lengths of vector.
		(i >= 0 ? @indices.index(i) : @indices.index(@size + i)) || @size
	end

	# Default value when accessing
	def default(i)
		(-@size...@size) === i ? 0 : nil
	end

	# Access element with index i
	public
	def [](i)
		@values[select_index(i)] || default(i)
	end

	alias component []

	#############
	# Iteration #
	#############

	# iterate over all elements
	private
	def iterate_all_elements
		# NOTE: Implementation can be optimized
		# by not searching for the index every time.
		@size.times{ |i| yield self[i], i }
	end

	# iterate over all non-zero elements
	def iterate_non_zero_elements
		@values.zip(@indices, &Proc.new)
	end

	@@iterators = {
		:all => :iterate_all_elements,
		:non_zero => :iterate_non_zero_elements
	}

	# Iterate over elements based on selector
	public
	def each(selector=:all)
		return to_enum(:each, selector) unless block_given?
		each_with_index(selector){ |x, i| yield x }
	end

	# Iterate over elements with index based on selector
	def each_with_index(selector=:all)
		return to_enum(:each_with_index, selector) unless block_given?
		send(@@iterators[selector], &Proc.new)
	end

	# Iterate over both vector's elements
	def each2(v)
		each2_with_index(v){ |x, y, i| yield x, y }
	end

	# Iterate over both vector's elements with index
	def each2_with_index(v)
		each_with_index(){ |x, i| yield x, v[i], i }
	end

	# Create new vector based on selector
	def map(selector=:all)
		VectorBuilder.create(:sparse, size) { |b|
			each_with_index(selector){ |x, i| b[i] = yield x }
		}.to_vec
	end

	alias collect map

	# Create new vector that has values of both vectors
	def map2(v)
		VectorBuilder.create(:sparse, size) { |b|
			each2_with_index(v){ |x, y, i| b[i] = yield x, y }
		}.to_vec
	end

	# Create new array that has values of both vectors
	def collect2(v)
		map2(v, &Proc.new).to_a
	end

	##############
	# Properties #
	##############

	attr_reader :size
	alias length size

	# Get magnitude of vector
	def magnitude
		Math.sqrt(each(:non_zero).map{ |x| x**2 }.reduce(:+))
	end

	alias r magnitude
	alias norm magnitude

	##############
	# Arithmetic #
	##############

	# Calculate inner_product of self * v
	def inner_product(v)
		each_with_index(:non_zero).map{ |x, i| x * v[i] }.reduce(0, :+)
	end

	# Calculate self * y
	private
	def scalar_multiply(y)
		map(:non_zero){ |x| x * y }
	end

	# Calculate multiplication of self * matrix
	def matrix_multiply(matrix)
		# TODO: use smart matrix builder.
		MatrixBuilder.create(:complete, size, matrix.column_size) { |b|
			size.times{ |i| size.times { |j|
				b[i, j] = self[i] * matrix[0, j]
			}}
		}.to_mat
		
	end

	@@multipliers = OverloadTable.new({
		Numeric => :scalar_multiply,
		VectorContract => :inner_product,
		MatrixContract => :matrix_multiply
	})

	# Multiply vector by argument
	public
	def *(x)
		return apply_through_coercion(x, :*) unless @@multipliers.include?(x)
		send(@@multipliers.select(x), x)
	end

	# Multiple vector by argument
	def /(x)
		return apply_through_coercion(x, :/) unless x.is_a?(Numeric)
		map{ |y| y / x }
	end

	# Add vector to vector
	private
	def vector_add(v)
		map2(v){ |x, y| x + y }
	end

	# Add matrix to vector
	def matrix_add(m)
		# TODO: Use smart matrix builder
		MatrixBuilder.create(:complete, size, 1) { |builder|
			each_with_index{ |x, i| builder[i, 0] = x + m[i, 0] }
		}.to_mat
	end

	@@adders = OverloadTable.new({
		VectorContract => :vector_add,
		MatrixContract => :matrix_add
	})

	# Add argument to vector
	public
	def +(x)
		return apply_through_coercion(x, :+) unless @@adders.include?(x)
		send(@@adders.select(x), x)
	end

	# Subtract argument from vector
	def -(x)
		return apply_through_coercion(x, :-) unless @@adders.include?(x)
		self + -x
	end

	alias +@ clone

	# Return vector where all elements are timesed by -1
	def -@
		map(:non_zero){ |x| -x }
	end

	# Normalize vector
	def normalize
		self / norm
	end

	# Take complex conjugate of vector
	def conjugate
		map(:non_zero){ |x| x.conj }
	end

	############
	# Equality #
	############

	# Determine if vectors equal
	def ==(other)
		other.is_a?(VectorContract) &&
		self.size == other.size &&
		zip(other).all?{ |x, y| x == y }
	end

	# Determine if implementations equal
	def eql?(other)
		other.is_a?(SparseVectorImpl) &&
		self.size == other.size &&
		zip(other).all?{ |x, y| x.eql?(y) }
	end

	# Return vector as hash
	def hash
		[@indices, @values].hash
	end

	###############
	# Conversions #
	###############

	# Convert vector to matrix
	def covector
		MatrixBuilder.create(:sparse, 1, size) { |builder|
			each_with_index(:non_zero){ |x, j| builder[0, j] = x }
		}.to_mat
	end

	# Convert vector to array
	def to_a
		each.to_a
	end

	# Coerce x into Scalar
	def coerce(x)
		[Scalar.new(x), self]
	end

	# Convert vector to string
	def to_s
		"SparseVector[#{each.to_a.join(', ')}]"
	end

	include VectorContract
end
