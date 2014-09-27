require 'test/unit'
require_relative 'contract'

module MatrixContract
	extend Contract
	include Test::Unit::Assertions

	ADD_SUB_TYPE = "Add_Sub"
	MULT_DIV_TYPE = "Mult_Div"
	
	def invariant
		# TODO: Class invariant
	end

	####################
	# Common Contracts #
	####################
	
	def self.add_sub_postcondition(method_name, &numBlock)
		add_postcondition_contract(method_name) do |instance, matrix2, result, *args|
			matrix2 = instance.convert_vector_to_matrix(ADD_SUB_TYPE, matrix2)
			if instance.is_matrix?(matrix2)
				if instance.empty?
					assert_equal(
						instance, result,
						instance.generic_postcondition_failure(method_name, result)
					)
				else
					assert(
						result.each_with_index.all? do |val, rowId, colId|
							numBlock.call(instance, matrix2, rowId, colId) == val
						end,
						instance.generic_postcondition_failure(method_name, result)
					)
				end
			else
				coercion = value.coerce(self)
				assert_equal(
					coercion[0].send(method_name, coercion[1]),
					result,
					instance.generic_postcondition_failure(method_name, result)
				)
			end
		end
	end
	
	def self.mult_div_postcondition(method_name, &numBlock)
		add_postcondition_contract(method_name) do |instance, value, result, *args|
			value = instance.convert_vector_to_matrix(MULT_DIV_TYPE, value)
			if instance.is_matrix?(value)
				if instance.empty? || value.empty?
					instance.empty_matrix_mult_div method_name, value, result
				else
					if method_name == "/"
						value = value.inverse
					end
					instance.contract_matrix_multiply method_name, value, result
				end
			elsif value.is_a?(Numeric)
				assert(
					result.each_with_index.all? do |val, rowId, colId|
						numBlock.call(instance, value, rowId, colId) == val
					end,
					instance.generic_postcondition_failure(method_name, result)
				)
			else
				coercion = value.coerce(instance)
				assert_equal(
					coercion[0].send(method_name, coercion[1]),
					result,
					instance.generic_postcondition_failure(method_name, result)
				)
			end

		end
	end
	
	def self.require_multipliable_arg(method_name)
		add_precondition_contract(method_name) do |instance, value, *args|
			matrix2 = instance.convert_vector_to_matrix(MULT_DIV_TYPE, value)
			if instance.is_matrix?(matrix2) 
				assert_equal(
					instance.column_size, matrix2.row_size, 
					"Number of columns in matrix 1 must match " \
					"the number of rows in matrix 2."
				)
			elsif !matrix2.is_a?(Numeric)
				assert_nothing_raised \
					"#{method_name} requires either a matrix, a " \
					"number or a value that can be coerced into one." do
						matrix2.coerce(instance)
					end				
			end

		end
	end
	
	def self.require_numeric_arg(method_name)
		add_precondition_contract(method_name) do |instance, value, *args|
			assert(
				value.is_a?(Numeric), 
				"#{method_name} requires a numeric argument. \n" \
				"You provided: #{value}"
			)
		end
	end
	
	def self.require_same_size_matrix(method_name)
		add_precondition_contract(method_name) do |instance, matrix2, *args|
			# Allow vectors
			matrix2 = instance.convert_vector_to_matrix(ADD_SUB_TYPE, matrix2)
			if instance.is_matrix?(matrix2)
				errorMsg = "Matrix dimensions mismatch. \n" \
					"Matrix 1: rows = #{instance.row_size} cols = #{instance.column_size} \n" \
					"Matrix 2: rows = #{matrix2.row_size} cols = #{matrix2.column_size}"
				assert_equal(instance.row_size, matrix2.row_size, errorMsg)
				assert_equal(instance.column_size, matrix2.column_size, errorMsg)
			else
				assert_nothing_raised \
					"#{method_name} requires either a matrix, a " \
					"number or a value that can be coerced into one." do
						matrix2.coerce(instance)
					end
			end
		end
	end

	def self.require_square(method_name)
		add_precondition_contract(method_name) do |instance, *args|
			assert(
				instance.square?,
				"#{method_name} can only be called " \
				"on a square matrix.\n" \
				"This matrix is #{instance.row_size} " \
				"by #{instance.column_size}"
			)
		end
	end

	def self.require_real(method_name)
		add_precondition_contract(method_name) do |instance, *args|
			assert(
				instance.real?,
				"#{method_name} can only be called " \
				"on a real matrix.\n" \
				"This matrix has imaginary entries: \n" \
				"#{instance}"
			)
		end
	end
	
	def self.require_regular(method_name)
		add_precondition_contract(method_name) do |instance, *args|
			assert(
				instance.regular?,
				"#{method_name} can only be called " \
				"on a regular matrix.\n" \
				"This matrix has rank: #{instance.rank} \n" \
				"which is less than row size: #{instance.row_size}"
			)
		end
	end
	
	def self.const_arguments(method_name)
		add_invariant_contract(method_name) do |instance, *args, &block|
			old_args = args.map do |x|
				begin
					x.clone
				rescue
					x
				end
			end
			block.call
			assert_equal(
				old_args, args,
				"method #{instance.class.name}.#{method_name} " \
				"modified 2nd matrix.\n"
			)
		end
	end

	#########################
	# Common Error Messages #
	#########################

	def generic_postcondition_failure(method_name, result, *args)
		if args.length == 0
			"#{method_name} returned an incorrect result.\n" \
			"Returned #{result} for the following matrix:\n" \
			"#{self}"
		else
			"#{method_name} returned an incorrect result.\n" \
			"Returned #{result} for the following matrix and args:\n" \
			"Matrix: #{self}; Arguments: #{args}"
		end
	end 
	
	###########################
	# Common Helper Functions #
	###########################
	
	def is_matrix?(value)
		return ( 
			value.respond_to?(:row) && value.respond_to?(:column) \
			&& value.respond_to?(:upper_triangular?) \
			&& value.respond_to?(:lower_triangular?) 
		)
	end
	
	def contract_matrix_multiply(oper, value, result)
		assert( 
			result.each_with_index.all? do |val, rowId, colId|
				val == row(rowId).zip(value.column(colId)).map{ |x, y| x * y }.reduce(:+)
			end,
			generic_postcondition_failure(oper, result)
		)
	end
	
	def convert_vector_to_matrix(type, matrix2)
		if matrix2.respond_to?(:covector)
			matrix2 = matrix2.covector
			if self.row_size > 1 && type == ADD_SUB_TYPE
				matrix2 = matrix2.transpose
			elsif self.row_size == 1 && type == MULT_DIV_TYPE
				
			end
		end
		return matrix2
	end
	
	def empty_matrix_mult_div(oper, matrix2, result)
		if empty? && matrix2.empty?
			assert_equal(
				Matrix.zero(row_size, matrix2.column_size),
				result,
				generic_postcondition_failure(oper, result)
			)
		else
			assert_equal(
				Matrix.empty(row_size, matrix2.column_size),
				result,
				generic_postcondition_failure(oper, result)
			)
		end
	end

	##############
	# Properties #
	##############

	def diagonal_postcondition?(result)
		assert_equal(
			each_with_index.all?{ |x, i, j| i == j || x == 0 },
			result,
			generic_postcondition_failure("diagonal?", result)
		)
	end

	require_square "diagonal?"
	const "diagonal?"

	def empty_postcondition?(result)
		assert_equal(
			count == 0,
			result,
			generic_postcondition_failure("empty?", result)
		)
	end

	const "empty?"

	def hermitian_postcondition?(result)
		assert_equal(
			self == self.conjugate.transpose,
			result,
			generic_postcondition_failure("hermitian?", result)
		)
	end

	require_square "hermitian?"
	const "hermitian?"

	def lower_triangular_postcondition?(result)
		assert_equal(
			each_with_index.all?{ |x, i, j| i >= j || x == 0 },
			result,
			generic_postcondition_failure("lower_triangular?", result)
		)
	end

	require_square "lower_triangular?"
	const "lower_triangular?"

	def normal_postcondition?(result)
		assert_equal(
			self * conjugate.transpose == conjugate.transpose * self,
			result,
			generic_postcondition_failure("normal?", result)
		)
	end

	require_square "normal?"
	const "normal?"

	def orthogonal_postcondition?(result)
		assert_equal(
			transpose == inverse,
			result,
			generic_postcondition_failure("orthogonal?", result)
		)
	end

	require_square "orthogonal?"
	require_real "orthogonal?"
	const "orthogonal?"

	def permutation_postcondition?(result)
		def permutation_vector?(vector)
			non_zeros = vector.select { |x| x != 0 }
			non_zeros.length == 1 && non_zeros[0] == 1
		end
		assert_equal(
			row_vectors.all?{ |v| permutation_vector?(v) } &&
			column_vectors.all?{ |v| permutation_vector?(v) },
			result,
			generic_postcondition_failure("permutation?", result)
		)
	end

	require_square "permutation?"
	const "permutation?"

	def real_postcondition?(result)
		assert_equal(
			all?{ |x| x.real? },
			result,
			generic_postcondition_failure("real?", result)
		)
	end

	const "real?"

	def regular_postcondition?(result)
		assert_equal(
			rank == row_size,
			result,
			generic_postcondition_failure("regular?", result)
		)
	end

	require_square "regular?"
	const "regular?"

	def singular_postcondition?(result)
		assert_equal(
			rank != row_size,
			result,
			generic_postcondition_failure("singular?", result)
		)
	end

	require_square "singular?"
	const "singular?"

	def square_postcondition?(result)
		assert_equal(
			row_size == column_size,
			result,
			generic_postcondition_failure("square?", result)
		)
	end

	const "square?"

	def symmetric_postcondition?(result)
		assert_equal(
			each_with_index.all?{ |x, i, j| x == self[j, i] },
			result,
			generic_postcondition_failure("symmetric?", result)
		)
	end

	require_square "symmetric?"
	const "symmetric?"

	def unitary_postcondition?(result)
		assert_equal(
			conjugate.transpose == inverse,
			result,
			generic_postcondition_failure("unitary?", result)
		)
	end

	require_square "unitary?"
	const "unitary?"

	def upper_triangular_postcondition?(result)
		assert_equal(
			each_with_index.all?{ |x, i, j| j >= i || x == 0 },
			result,
			generic_postcondition_failure("upper_triangular?", result)
		)
	end

	require_square "upper_triangular?"
	const "upper_triangular?"

	def zero_postcondition?(result)
		assert_equal(
			all?{ |x| x == 0 },
			result,
			generic_postcondition_failure("zero?", result)
		)
	end

	const "zero?"
	
	##############
	# Arithmetic #
	##############
	
	require_multipliable_arg "*"
	mult_div_postcondition "*" do |instance, value, rowId, colId|
		instance[rowId,colId] * value
	end
	const "*"
	const_arguments "*"
	
	require_same_size_matrix "+"
	add_sub_postcondition "+" do |instance, matrix2, rowId, colId|
		instance[rowId, colId] + matrix2[rowId, colId]
	end
	const "+"
	const_arguments "+"
	
	require_same_size_matrix "-"
	add_sub_postcondition "-" do |instance, matrix2, rowId, colId|
		instance[rowId, colId] - matrix2[rowId, colId]
	end
	const "-"
	const_arguments "-"
	
	def op_divide_precondition(value)
		if is_matrix?(value)
			assert(
				value.regular?, 
				"/ operator requires the second matrix to be invertible."
			)
		end
	end
		
	require_multipliable_arg "/"
	mult_div_postcondition "/" do |instance, value, rowId, colId|
		instance[rowId,colId] / value
	end
	const "/"
	const_arguments "/"
	
	def op_power_postcondition(value, result)
		if empty?
			assert_equal(
				self, result,
				generic_postcondition_failure("**", result)
			)
		else
			if value % 1 == 0
				if value == 0
					assert_equal(
						identity(row_size), result,
						generic_postcondition_failure("**", result)
					)
				elsif value < 0
					expected = self
					(1..value).each do |i|
						expected = expected / self
					end
					assert_equal(
						expected, result,
						generic_postcondition_failure("**", result)
					)
				else
					expected = self
					(2..value).each do |i|
						expected = expected * self
					end
					assert_equal(
						expected, result,
						generic_postcondition_failure("**", result)
					)
				end
			else
				v, d, v_inv = eigensystem
				diagonalElements = d.each_with_index.select{|x,i,j| i==j}.collect{|x| x[0]}
				assert_equal(
					v * Matrix.diagonal(*diagonalElements) * v_inv,
					result,
					generic_postcondition_failure("**", result)
				)
			end
		end
	end
	
	require_numeric_arg "**"
	require_square "**"
	const "**"
		
	def inverse_postcondition(result)
		assert_equal(
			(self * result).round(5), Matrix.identity(row_size),
			generic_postcondition_failure("inverse", result)
		)
	end
	
	require_regular "inverse"
	require_square "inverse"
	const "inverse"

	##################
	# Decompositions #
	##################

	def eigensystem_postcondition(result)
		v, d, v_inv = *result

		assert(
			d.diagonal?,
			"eigensystem returned an invalid matrix of eigenvalues:\n" \
			"returned #{d} for matrix #{self}"
		)

		assert_equal(
			v.inv.round(5),
			v_inv.round(5),
			"the inverse of the eigenvector matrix was incorrect:\n" \
			"v = #{v}, v_inv = #{v_inv}, original matrix: #{self}"
		)

		assert_equal(
			self.round(5),
			(v * d * v_inv).round(5),
			"eigensystem returned an incorrect result:\n" \
			"v = #{v}, v_inv = #{v_inv}, d = #{d}\n" \
			"original matrix = #{self}"
		)
	end

	require_square "eigensystem"
	const "eigensystem"

	def lup_postcondition(result)
		l, u, p = *result

		assert(
			l.lower_triangular?,
			"The 'l' returned by the lup decomposition was not\n" \
			"lower triangular: #{l}"
		)

		assert(
			u.upper_triangular?,
			"The 'u' returned by the lup decomposition was not\n" \
			"upper triangular: #{u}"
		)

		assert(
			p.permutation?,
			"The 'p' returned by the lup decomposition was not\n" \
			"a permutation matrix: #{p}"
		)

		assert_equal(
			(l * u).round(5),
			(p * self).round(5),
			"The lup decomposition was incorrect:\n" \
			"l = #{l}, u = #{u}, p = #{p}\n" \
			"original matrix = #{self}"
		)
	end

	require_square "lup"
	const "lup"

	######################
	# Complex Arithmetic #
	######################

	def conjugate_postcondition(result)
		assert(
			zip(result).all? { |a, b|
				a.real == b.real && a.imag == -b.imag
			},
			generic_postcondition_failure("conjugate", result)
		)
	end

	const "conjugate"

	def imaginary_postcondition(result)
		assert(
			zip(result).all? { |a, b| b.imag == 0 && a.imag == b.real },
			generic_postcondition_failure("imaginary", result)
		)
	end

	const "imaginary"

	def real_postcondition(result)
		assert(
			zip(result).all? { |a, b| a.real == b.real && b.imag == 0 },
			generic_postcondition_failure("real", result)
		)
	end

	const "real"

	def rect_postcondition(result)
		assert_equal(
			result,
			[real, imag],
			generic_postcondition_failure("real", result)
		)
	end

	const "rect"

	###################
	# Type conversion #
	###################

	def coerce_precondition(value)
		assert(
			value.is_a?(Numeric),
			"#{self.class} can't be coerced into #{value.class}"
		)
	end

	def coerce_postcondition(value, result)
		other, me = *result
		assert_nothing_raised(
			"Coersion from #{value} failed.  Result: #{result}"
		) { other * me }
	end

	const "coerce"

	def row_vectors_postcondition(result)
		assert(
			each_with_index.all? { |x, i, j| x == result[i][j] },
			generic_postcondition_failure("row_vectors", result)
		)
	end

	const "row_vectors"

	def column_vectors_postcondition(result)
		assert(
			each_with_index.all? { |x, i, j| x == result[j][i] },
			generic_postcondition_failure("column_vectors", result)
		)
	end

	const "column_vectors"

	def to_a_postcondition(result)
		assert(
			each_with_index.all? { |x, i, j| x == result[i][j] },
			generic_postcondition_failure("to_a", result)
		)
	end

	const "to_a"
end
