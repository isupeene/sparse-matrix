require 'test/unit'
require_relative 'contract'

module MatrixContract
	extend Contract
	include Test::Unit::Assertions

	ADD_SUB_TYPE = "Add_Sub"
	MULT_DIV_TYPE = "Mult_Div"
	
	def invariant
		assert(row_size >= 0, "Row size is invalid.")
		assert(column_size >= 0, "Column size is invalid.")
		assert(count == row_size * column_size, "Number of elements is less than it should be.")
		assert(all?{ |x| x.is_a?(Numeric) }, "Non-number elements present in matrix.")
		assert(self.transpose.transpose == self, "Matrix modified by transposing it.")
		m1 = Matrix.build(row_size, column_size) {|i, j| i == j ? 1 : 0}
		m2 = Matrix.build(row_size, column_size) {|i, j| i == j ? 2 : 0}
		m3 = Matrix.build(column_size, row_size) {|i, j| i == j ? 3 : 0}
		m4 = Matrix.build(column_size, row_size) {|i, j| i == j ? 4 : 0}
		assert_equal(
			self + m1, m1 + self,
			"Matrix addition was not commutative."
		)
		assert_equal(
			(self + m1) + m2, self + (m1 + m2),
			"Matrix addition was not associative."
		)
		assert_equal(
			(self * m3) * m2, self * (m3 * m2),
			"Matrix multiplication was not associative."
		)
		assert_equal(
			self * (m3 + m4), (self * m3) + (self * m4),
			"Matrix multiplication was not distributive."
		)
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
				coercion = matrix2.coerce(instance)
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
	
	def self.return_matrix(method_name)
		add_postcondition_contract(method_name) do |instance, *args, result|
			assert(
				result.class.include?(MatrixContract),
				"Method #{method_name} expected to return a matrix.\n" \
				"Returned a #{result.class} instead."
			)
		end
	end
	
	###########################
	# Common Helper Functions #
	###########################
	
	def is_matrix?(value)
		value.class.include?(MatrixContract)
	end
	
	def contract_matrix_multiply(oper, value, result)
		assert( 
			result.each_with_index.all? do |val, rowId, colId|
				val == row(rowId).zip(value.column(colId)).map{ |x, y| x * y }.reduce(:+)
			end,
			generic_postcondition_failure(oper, result)
		)
	end
	
	def contract_gaussian_elimination
		a = to_a
		last_col = column_size - 1
		last_row = row_size - 1
		pivot_row = 0
		0.upto(last_col) do |k|
			switch_row = (pivot_row .. last_row).find {|row|
				a[row][k] != 0
			}
			if switch_row
				a[switch_row], a[pivot_row] = a[pivot_row], a[switch_row] unless pivot_row == switch_row
				pivot = a[pivot_row][k]
				(pivot_row + 1).upto(last_row) do |i|
					ai = a[i]
					(k + 1).upto(last_col) do |j|
						ai[j] =  (ai[j] - ai[k].to_f / pivot.to_f * a[pivot_row][j])
					end
					ai[k] = 0
				end
				pivot_row += 1
			end
		end
		return self.class.rows(a)
	end
	
	def convert_vector_to_matrix(type, matrix2)
		if matrix2.respond_to?(:covector)
			matrix2 = matrix2.covector
			if self.row_size > 1 && type == ADD_SUB_TYPE
				matrix2 = matrix2.transpose
			elsif self.row_size == 1 && type == MULT_DIV_TYPE
				matrix2 = matrix2.transpose
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
	return_matrix "*"
	const "*"
	const_arguments "*"
	
	require_same_size_matrix "+"
	add_sub_postcondition "+" do |instance, matrix2, rowId, colId|
		instance[rowId, colId] + matrix2[rowId, colId]
	end
	return_matrix "+"
	const "+"
	const_arguments "+"
	
	require_same_size_matrix "-"
	add_sub_postcondition "-" do |instance, matrix2, rowId, colId|
		instance[rowId, colId] - matrix2[rowId, colId]
	end
	return_matrix "-"
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
	return_matrix "/"
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
				diagonalElements = d.each(:diagonal).collect{|x| x[0]}
				assert_equal(
					v * Matrix.diagonal(*diagonalElements) * v_inv,
					result,
					generic_postcondition_failure("**", result)
				)
			end
		end
	end
	
	require_operand_types "**", Numeric
	require_square "**"
	return_matrix "**"
	const "**"
	
	def op_equal_postcondition(value, result)
		assert_equal(row_size, value.row_size, generic_postcondition_failure("==", result))
		assert_equal(column_size, value.column_size, generic_postcondition_failure("==", result))
		assert_equal(
			zip(value).all? {|x,y| x == y}, result,
			generic_postcondition_failure("==", result)
		)
	end
	
	require_operand_types "==",
		MatrixContract
	const_arguments "=="
	const "=="
		
	def inverse_postcondition(result)
		assert_equal(
			(self * result).round(5), Matrix.identity(row_size),
			generic_postcondition_failure("inverse", result)
		)
	end
	
	require_regular "inverse"
	require_square "inverse"
	return_matrix "inverse"
	const "inverse"
	
	#############
	# Functions #
	#############
	
	def determinant_postcondition(result)
		value = self
		unless upper_triangular?
			value = contract_gaussian_elimination
		end
		assert_equal(
			value.each_with_index.select{|x,i,j| i==j}.collect{|x| x[0]}.reduce(:*),
			result,
			generic_postcondition_failure("determinant", result)
		)
	end
	
	require_square "determinant"
	const "determinant"
	
	def minor_precondition(*args)
		assert( (args.size == 2 && args.all? {|x| x.is_a?(Range)}) ||
			(args.size == 4 && args.all? {|y| y % 1 == 0}),
			"Wrong number/types of args to minor. \n" \
			"Requires: 2 ranges or 4 integers, Provided: #{args.size}"
		)
	end
	
	def minor_postcondition(*args, result)
		case args.size
		when 2
			row_range, col_range = args
		when 4
			row_start, row_count, col_start, col_count = args
			row_range = Range.new(row_start, row_start + row_count - 1)
			col_range = Range.new(col_start, col_start + col_count - 1)
		end
			
		assert(
			each_with_index.select{ |x,i,j| row_range === i && col_range === j }.all?{ |x, i, j|
				x == result[i - row_range.begin, j - col_range.begin]
			},
			generic_postcondition_failure("minor", result)
		)
	end

	return_matrix "minor"
	const "minor"
	
	def rank_postcondition(result)
		value = self
		unless upper_triangular?
			value = contract_gaussian_elimination
		end
		nonzero_rows = value.row_vectors.count{|x| x.any?{|y| y != 0} }
		
		assert_equal(
			[column_size, nonzero_rows].min,
			result,
			generic_postcondition_failure("rank", result)
		)
	end
	
	const "rank"
	
	def round_postcondition(value, result)
		assert_equal(row_size, result.row_size, generic_postcondition_failure("round", result))
		assert_equal(column_size, result.row_size, generic_postcondition_failure("round", result))
		assert(
			zip(result).all?{|x, y| x.round(value) == y},
			generic_postcondition_failure("round", result)
		)
	end
	
	require_argument_types "round", [Numeric]
	return_matrix "round"
	const "round"
	
	def trace_postcondition(result)
		assert_equal(
			each(:diagonal).reduce(:+),
			result,
			generic_postcondition_failure("trace", result)
		)
	end
	
	require_square "trace"
	const "trace"
	
	def transpose_postconiditon(result)
		assert(
			each_with_index.all?{|x,i,j| x == result[j,i]},
			generic_postcondition_failure("transpose", result)
		)
	end
	
	return_matrix "transpose"
	const "transpose"
	
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
