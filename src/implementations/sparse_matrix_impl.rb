require 'matrix'

require_relative "../sparse_matrix_functions"
require_relative "../contracts/matrix_contract"
require_relative "../builders/vector_builder"

class SparseMatrixImpl < Matrix
	include SparseMatrixFunctions

	##################
	# Initialization #
	##################

	def initialize(builder)
		@row_size = builder.row_size
		@column_size = builder.column_size

		@rows = Array.new(builder.row_size) { |i|
			builder.row(i).to_vec
		}
	end

	def initialize_copy(other)
		@rows = other.rows
	end

	##########
	# Access #
	##########

	attr_reader :row_size
	attr_reader :column_size

	protected
	attr_reader :rows

	public
	def [](i, j)
		@rows[i][j]
	end

	protected
	def iterate_row(i)
		row(i).each{ |x| yield x }
	end

	def iterate_column(i)
		column(i).each{ |x| yield x }
	end

	public
	def row(i, &block)
		return iterate_row(i, &block) if block_given?
		@rows[i]
	end

	def column(j, &block)
		return iterate_column(j, &block) if block_given?
		VectorBuilder.create(:sparse, row_size) { |builder|
			@rows.each.with_index { |row, i| builder[i] = row[j] }
		}.to_vec
	end

	#############
	# Iteration #
	#############

	protected
	def iterate_non_zero
		@rows.each.with_index { |row, i|
			row.each_with_index(:non_zero){ |x, j| yield x, i, j }
		}
	end

	##############
	# Properties #
	##############

	def lower_triangular?
		each_with_index(:non_zero).all?{ |x, i, j| i >= j }
	end

	def upper_triangular?
		each_with_index(:non_zero).all?{ |x, i, j| i <= j }
	end

	def diagonal?
		each_with_index(:non_zero).all?{ |x, i, j| i == j }
	end

	def permutation?
		row_vectors.all? { |row|
			row.each(:non_zero).count == 1 &&
			row.each(:non_zero).count(1) == 1
		} &&
		column_vectors.all? { |column|
			column.each(:non_zero).count == 1 &&
			column.each(:non_zero).count(1) == 1
		}
	end

	##############
	# Arithmetic #
	##############

	# TODO: See if inverse can be sped up for generic sparse matrix.

	####################
	# Matrix Functions #
	####################

	# TODO: See if determinant, rank and transpose  can be sped up
	# for generic sparse matrix.

	##################
	# Decompositions #
	##################

	# TODO: Investigate if these can be done more efficiently.

	include MatrixContract
end
