require 'test/unit'
require_relative '../src/contracts/matrix_builder_contract.rb'
require_relative '../src/complete_matrix_builder'

module MatrixBuilderTestBase

	def setup
		@b1 = builder_factory.new(3, 4)
		@b2 = builder_factory.new(0, 0)
	end

	def test_size
		assert_equal([3, 4], [@b1.row_size, @b1.column_size])
		assert_equal([0, 0], [@b2.row_size, @b2.column_size])
	end

	def test_element_access
		@b1.row_size.times do |i|
			@b1.column_size.times do |j|
				@b1[i, j] = i * j
				assert_equal(i * j, @b1[i, j])
			end
		end
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
end

class CompleteMatrixBuilderTest < Test::Unit::TestCase
	include MatrixBuilderTestBase

	def builder_factory
		CompleteMatrixBuilder
	end
end
