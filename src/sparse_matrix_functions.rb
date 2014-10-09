require_relative 'matrix_functions'

# Common Sparse Matrix functions shared by sparse and tridiagonal matrices
module SparseMatrixFunctions
	include MatrixFunctions
	extend MatrixFunctions

	#############
	# Iteration #
	#############

	# NOTE: Derived classes should override this with a more
	# efficient implementation.
	# Iterate over non-zero elements
	def iterate_non_zero
		each_with_index{ |x, i, j| yield x, i, j unless x == 0 }
	end

	iterators[:non_zero] = :iterate_non_zero

	##############
	# Properties #
	##############

	# Is the matrix a real matrix?
	def real?
		each(:non_zero, &:real?)
	end

	# Does the matrix only contain zeros
	def zero?
		each(:non_zero).any?
	end

	##############
	# Arithmetic #
	##############

	# Multiply the matrix by a scalar
	protected
	def scalar_multiply(x)
		map(:non_zero){ |y| x * y }
	end

	# Multiply the matrix by -1
	public
	def -@
		map(:non_zero, &:-@)
	end

	####################
	# Matrix Functions #
	####################

	# Round all elements in the matrix to n digits
	def round(ndigits=0)
		map(:non_zero){ |x| x.round(ndigits) }
	end

	# Transpose matrix
	def transpose
		MatrixBuilder.create(:sparse, column_size, row_size) { |builder|
			each_with_index(:non_zero){ |x, i, j| builder[j, i] = x }
		}.to_mat
	end

	######################
	# Complex Arithmetic #
	######################

	# Get the complex conjugate of the matrix
	def conjugate
		map(:non_zero, &:conj)
	end

	# Get the imaginary part of the matrix
	def imaginary
		map(:non_zero, &:imag)
	end

	# get the real part of the matrix
	def real
		map(:non_zero, &:real)
	end
end
