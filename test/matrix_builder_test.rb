require 'test/unit'
require_relative '../src/contracts/matrix_builder_contract.rb'
require_relative '../src/builders/complete_matrix_builder'
require_relative '../src/builders/sparse_matrix_builder'
require_relative '../src/builders/dumb_matrix_builder'

module MatrixBuilderTestBase

	def setup
		@b1 = builder_factory.send(:new, 3, 4)
		@b2 = builder_factory.send(:new, 0, 0)
		@b3 = builder_factory.send(:new, 3, 4)
		@b4 = builder_factory.send(:new, 3, 4)
	end

	def test_size
		assert_equal([3, 4], [@b1.row_size, @b1.column_size])
		assert_equal([0, 0], [@b2.row_size, @b2.column_size])
	end

	def test_element_access
		@b1.each_with_index { |x, i, j| @b1[i, j] = i * j }
		assert(@b1.each_with_index.all?{ |x, i, j| @b1[i, j] == i * j })
	end

	def test_to_mat
		matrix = @b1.to_mat
		assert(matrix.each_with_index.all?{ |x, i, j| x == @b1[i, j] })
		assert_equal(
			[matrix.row_size, matrix.column_size],
			[@b1.row_size, @b1.column_size]
		)

		assert(@b2.to_mat.empty?)
	end

	def test_equality
		@b4[0, 0] = 5
		assert(@b1 != @b2 && !(@b1 == @b2))
		assert(@b1 == @b3 && !(@b1 != @b3))
		assert(@b1 != @b4 && !(@b1 == @b4))

		assert(@b2 != @b1 && !(@b2 == @b1))
		assert(@b2 != @b3 && !(@b2 == @b3))
		assert(@b2 != @b4 && !(@b2 == @b4))

		assert(@b3 == @b1 && !(@b3 != @b1))
		assert(@b3 != @b2 && !(@b3 == @b2))
		assert(@b3 != @b4 && !(@b3 == @b4))

		assert(@b4 != @b1 && !(@b4 == @b1))
		assert(@b4 != @b2 && !(@b4 == @b2))
		assert(@b4 != @b3 && !(@b4 == @b3))
	end
end

class CompleteMatrixBuilderTest < Test::Unit::TestCase
	include MatrixBuilderTestBase

	def builder_factory
		CompleteMatrixBuilder
	end
end

class SparseMatrixBuilderTest < Test::Unit::TestCase
	include MatrixBuilderTestBase

	def builder_factory
		SparseMatrixBuilder
	end
end

class DumbMatrixBuilderTest < Test::Unit::TestCase
	include MatrixBuilderTestBase

	def builder_factory
		DumbMatrixBuilder
	end
end
