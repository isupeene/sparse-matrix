require 'matrix'

require_relative 'overload_table'
require_relative 'scalar'
require_relative 'contracts/matrix_contract'
require_relative 'contracts/vector_contract'
require_relative 'builders/vector_builder'
require_relative 'builders/sparse_vector_builder'
require_relative 'builders/matrix_builder'
require_relative 'builders/sparse_matrix_builder'
require_relative 'builders/complete_matrix_builder'

class SparseVector
	include Enumerable
	include Matrix::CoercionHelper

	##################
	# Initialization #
	##################

	def initialize(builder)
		@size = builder.size
		@indices, @values = builder.transpose
	end

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

	private
	def select_index(i)
		# NOTE: Ruby 2.x provides bsearch, implemented in C,
		# which is more efficient than index.  Unfortunately,
		# a ruby implementation of bsearch will not be more
		# efficient than the built-in index method - which
		# is implemented in C - for most lengths of vector.
		(i >= 0 ? @indices.index(i) : @indices.index(@size + i)) || @size
	end

	def default(i)
		(-@size...@size) === i ? 0 : nil
	end

	public
	def [](i)
		@values[select_index(i)] || default(i)
	end

	alias component []

	#############
	# Iteration #
	#############

	private
	def iterate_all_elements
		# NOTE: Implementation can be optimized
		# by not searching for the index every time.
		@size.times{ |i| yield self[i], i }
	end

	def iterate_non_zero_elements
		@values.zip(@indices, &Proc.new)
	end

	@@iterators = {
		:all => :iterate_all_elements,
		:non_zero => :iterate_non_zero_elements
	}

	public
	def each(selector=:all)
		return to_enum(:each, selector) unless block_given?
		each_with_index(selector){ |x, i| yield x }
	end

	def each_with_index(selector=:all)
		return to_enum(:each_with_index, selector) unless block_given?
		send(@@iterators[selector], &Proc.new)
	end

	def each2(v, selector=:all)
		each2_with_index(v, selector){ |x, y, i| yield x, y }
	end

	def each2_with_index(v, selector=:all)
		each_with_index(selector){ |x, i| yield x, v[i], i }
	end

	def map(selector=:all)
		map2([], selector){ |x, _| yield x }
	end

	alias collect map

	def map2(v, selector=:all)
		VectorBuilder.create(:sparse, size) { |b|
			each2_with_index(v, selector){ |x, y, i| b[i] = yield x, y }
		}.to_vec
	end

	def collect2(v, selector=:all)
		map2(v, selector, &Proc.new).to_a
	end

	##############
	# Properties #
	##############

	attr_reader :size
	alias length size

	def magnitude
		Math.sqrt(each(:non_zero).map{ |x| x**2 }.reduce(:+))
	end

	alias r magnitude
	alias norm magnitude

	##############
	# Arithmetic #
	##############

	def inner_product(v)
		each_with_index(:non_zero).map{ |x, i| x * v[i] }.reduce(:+)
	end

	private
	def scalar_multiply(y)
		map(:non_zero){ |x| x * y }
	end

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

	public
	def *(x)
		return apply_through_coercion(x, :*) unless @@multipliers.include?(x)
		send(@@multipliers.select(x), x)
	end

	def /(x)
		return apply_through_coercioun(x, :/) unless x.is_a?(Numeric)
		map{ |y| y / x }
	end

	private
	def vector_add(v)
		map2(v){ |x, y| x + y }
	end

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

	public
	def +(x)
		return apply_through_coercion(x, :+) unless @@adders.include?(x)
		send(@@adders.select(x), x)
	end

	def -(x)
		return apply_through_coercion(x, :-) unless @@adders.include?(x)
		self + -x
	end

	alias +@ clone

	def -@
		map(:non_zero){ |x| -x }
	end

	def normalize
		self / norm
	end

	def conjugate
		map(:non_zero){ |x| x.conj }
	end

	############
	# Equality #
	############

	def ==(other)
		other.is_a?(VectorContract) &&
		self.size == other.size &&
		zip(other).all?{ |x, y| x == y }
	end

	def eql?(other)
		other.is_a?(SparseVector) &&
		self.size == other.size &&
		zip(other).all?{ |x, y| x.eql?(y) }
	end

	def hash
		[@indices, @values].hash
	end

	###############
	# Conversions #
	###############

	def covector
		MatrixBuilder.create(:sparse, 1, size) { |builder|
			each_with_index(:non_zero){ |x, j| builder[0, j] = x }
		}.to_mat
	end

	def to_a
		each.to_a
	end

	def coerce(x)
		[Scalar.new(x), self]
	end

	def to_s
		"SparseVector[#{each.to_a.join(', ')}]"
	end

	include VectorContract
end
