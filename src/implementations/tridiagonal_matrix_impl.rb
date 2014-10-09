require 'matrix'

require_relative "../contracts/matrix_contract.rb"
require_relative "../builders/vector_builder"
require_relative "../builders/sparse_vector_builder"
require_relative "../sparse_matrix_functions"

# Implementation of a tridiagonal matrix
class TridiagonalMatrixImpl < Matrix
	include SparseMatrixFunctions

	##################
	# Initialization #
	##################

	# Create new Tridiagonal Matrix based on builder specs
	def initialize(builder)
		@row_size = builder.row_size
		@column_size = builder.column_size

		@upper = VectorBuilder.create(:sparse, builder.row_size - 1) { |b|
			builder.each_with_index.select{ |x, i, j| i == j - 1 }.each{ |x, i|
				b[i] = x
			}
		}.to_vec

		@lower = VectorBuilder.create(:sparse, builder.row_size - 1) { |b|
			builder.each_with_index.select{|x, i, j| i == j + 1}.each{|x, _, j|
				b[j] = x
			}
		}.to_vec

		@diagonal = VectorBuilder.create(:sparse, builder.row_size) { |b|
			builder.each_with_index.select{|x, i, j| i == j }.each{ |x, i|
				b[i] = x
			}
		}.to_vec
	end

	# Create new tridiagonal matrix that is a copy of other
	def initialize_copy(other)
		@upper = other.upper
		@lower = other.lower
		@diagonal = other.diagonal
	end

	##########
	# Access #
	##########

	attr_reader :row_size
	attr_reader :column_size

	protected
	attr_reader :upper
	attr_reader :diagonal
	attr_reader :lower

	private
	@@vectors = {
		-1 => :upper,
		0 => :diagonal,
		1 => :lower
	}
	@@vectors.default = :default_vector

	# Default vector to represent diagonal lines
	attr_accessor :default_vector
	def default_vector
		default_vector ||= VectorBuilder.create(:sparse, 0).to_vec
	end

	# Select vector that contains element [i,j]
	def select_vector(i, j)
		send(@@vectors[i - j])
	end

	# Select index of element in vector based on [i,j]
	def select_index(i, j)
		[i, j].min
	end

	# Default value for element access
	def default(i, j)
		(-@row_size...@row_size) === i &&
		(-@column_size...@column_size) === j ?
			0 : nil
	end

	# Access element at [i,j]
	public
	def [](i, j)
		select_vector(i, j)[select_index(i, j)] || default(i, j)
	end

	# Get row i only containing values on the tridiagonal
	private
	def mini_row(i)
		Vector[@lower[i - 1] || 0,
		       @diagonal[i],
		       @upper[i] || 0]
	end

	# Get column j only containing values on the tridiagonal
	def mini_column(j)
		Vector[@upper[j - 1] || 0,
		       @diagonal[j],
		       @lower[j] || 0]
	end

	# Get entire row i
	public
	def row(i)
		VectorBuilder.create(:sparse, column_size) { |b|
			mini_row(i).each.with_index { |x, k| b[i + k - 1] = x	}
		}.to_vec
	end

	# Get entire column j
	def column(j)
		VectorBuilder.create(:sparse, row_size) { |b|
			mini_column(j).each.with_index { |x, k| b[j + k - 1] = x }
		}.to_vec
	end

	#############
	# Iteration #
	#############

	# Iterate over the diagonal
	protected
	def iterate_diagonal
		@diagonal.each_with_index{ |x, i| yield x, i, i }
	end

	# Iterate over non-zero elements
	def iterate_non_zero
		@upper.each_with_index(:non_zero){ |x, i| yield x, i, i + 1 }
		@diagonal.each_with_index(:non_zero){ |x, i| yield x, i, i }
		@lower.each_with_index(:non_zero){ |x, j| yield x, j + 1, j }
	end

	##############
	# Properties #
	##############

	# Get all mini_rows (rows with only values from tridiagonal)
	private
	def mini_rows
		return to_enum(:mini_rows) unless block_given?
		@row_size.times { |i| yield mini_row(i) }
	end

	# Get all mini_columns (columns with only values from tridiagonal)
	def mini_columns
		return to_enum(:mini_columns) unless block_given?
		@column_size.times { |j| yield mini_column(j) }
	end

	public
	attr_reader :row_size
	attr_reader :column_size

	# Check if matrix is hermitian
	def hermitian?
		@upper.zip(@lower).all? { |x, y| x == y.conj }
	end

	# Check if matrix is lower triangular
	def lower_triangular?
		!@upper.each(:non_zero).any?
	end

	# Check if matrix is upper triangular
	def upper_triangular?
		!@lower.each(:non_zero).any?
	end

	# Check if matrix is a permutation
	def permutation?
		mini_rows.all?{ |row| row.count(0) == 2 && row.count(1) == 1 } &&
		mini_columns.all?{ |col| col.count(0) == 2 && col.count(1) == 1 }
	end

	# Check if matrix is symmetric
	def symmetric?
		@upper.zip(@lower).all? { |x, y| x == y }
	end

	##############
	# Arithmetic #
	##############

	#def inverse
	# TODO: Eliminate lower,
	# Eliminate upper,
	# Divide by diagonal.
	# NOTE: The matrix CANNOT be singular.
	#end

	####################
	# Matrix Functions #
	####################

	# Get determinant of matrix from Matrix class
	def determinant
	# TODO: Eliminate lower, eliminate upper, multiply diagonal
	# NOTE: The matrix can be singular.
		# HACK: We're allocating a whole bunch of storage here so that the
		# built-in matrix determinant can do its thing, even though
		# there's a perfectly simple algorithm for finding the
		# determinant of a tridiagonal matrix.
		@rows ||= to_a
		super
	end

	#def rank
		# TODO: Gaussian elimination
	#end

	# Get trace of matrix
	def trace
		@diagonal.each(:non_zero).reduce(:+)
	end

	#def transpose
		# NOTE: It would be quicker to just create a new tri-diagonal
		# matrix, and just duplicate upper, lower and diagonal,
		# but we will need to extend the design to enable this.
		# TODO: Use sparse matrix builder
	#end

	##################
	# Decompositions #
	##################

	# TODO: Investigate if these can be done more efficiently.
end
