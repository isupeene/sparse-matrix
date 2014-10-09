require_relative 'matrix_functions'

module SparseMatrixFunctions
	include MatrixFunctions
	extend MatrixFunctions

	#############
	# Iteration #
	#############

	# NOTE: Derived classes should override this with a more
	# efficient implementation.
	def iterate_non_zero
		each_with_index{ |x, i, j| yield x, i, j unless x == 0 }
	end

	iterators[:non_zero] = :iterate_non_zero

	##############
	# Properties #
	##############

	def real?
		each(:non_zero, &:real?)
	end

	def zero?
		each(:non_zero).any?
	end

	##############
	# Arithmetic #
	##############

	protected
	def scalar_multiply(x)
		map(:non_zero){ |y| x * y }
	end

	public
	def -@
		map(:non_zero, &:-@)
	end

	####################
	# Matrix Functions #
	####################

	def round(ndigits=0)
		map(:non_zero){ |x| x.round(ndigits) }
	end

	def transpose
		MatrixBuilder.create(:sparse, column_size, row_size) { |builder|
			each_with_index(:non_zero){ |x, i, j| builder[j, i] = x }
		}.to_mat
	end

	######################
	# Complex Arithmetic #
	######################

	def conjugate
		map(:non_zero, &:conj)
	end

	def imaginary
		map(:non_zero, &:imag)
	end

	def real
		map(:non_zero, &:real)
	end
end
