require_relative "scalar"
require_relative "overload_table"
require_relative "enumerable"
require_relative "builders/matrix_builder"
require_relative "builders/complete_matrix_builder"
require_relative "builders/vector_builder"
require_relative "builders/complete_vector_builder"

# Functions shared by matrix implementations
module MatrixFunctions

	# An alias will make a method name refer to a method that has
	# the specified name *at the time the alias is defined*.  This
	# override function allows base classes to override the alias
	# by overriding the function it refers to.
	# Moreover, this allows us to alias functions that don't exist yet.
	def self.override(s1, s2)
		define_method(s1) do |*args, &block|
			send(s2, *args, &block)
		end
	end

	# Un-override clone - our classes implement initialize_copy.
	def clone
		Object.instance_method(:clone).bind(self).call
	end

	##########
	# Access #
	##########

	# This overrides the attr_reader in Matrix, so the built-in
	# Matrix functions will do the right thing most of the time.
	protected
	override :rows, :row_vectors

	public
	override :component, :[]

	# Return minor of matrix starting at i,j and going for num_rows and num_columns
	protected
	def minor_with_index(i, num_rows, j, num_columns)
		minor_with_range(i...(i + num_rows), j...(j + num_columns))
	end

	# Return minor of matrix that is contained in the given index range
	def minor_with_range(i_range, j_range)
		# TODO: Use smart matrix builder
		MatrixBuilder.create(:complete, i_range.count, j_range.count) { |b|
			i_range.each.with_index { |i_self, i|
				j_range.each.with_index { |j_self, j|
					b[i, j] = self[i_self, j_self]
				}
			}
		}.to_mat
	end

	@@minors = {
		2 => :minor_with_range,
		4 => :minor_with_index
	}

	# Return minor of a matrix
	public
	def minor(*args)
		send(@@minors[args.length], *args)
	end

	#############
	# Iteration #
	#############

	# Return each index in the matrix
	protected
	def each_index
		return to_enum(:each_index) unless block_given?
		row_size.times{ |i| column_size.times{ |j| yield i, j } }
	end

	# Select indices based on the condition
	def select_indices(condition)
		each_index.select{ |i, j| send(condition, i, j) }
	end

	# Possible ways to iterate
	@@iterators = Hash[[
		:all,
		:diagonal,
		:off_diagonal,
		:lower,
		:strict_lower,
		:upper,
		:strict_upper
	].map{ |s| [s, ("iterate_" + s.to_s).to_sym] }]
	def iterators
		@@iterators
	end
	
	# Define each method to select values based on selector
	@@iterators.each do |selector, symbol|
		define_method(symbol) do |&block|
			select_indices(selector).each { |i, j|
				block.call(self[i, j], i, j)
			}
		end
	end

	# For iterators, select all
	def all(i, j)
		true
	end

	# For iterators, select elements on diagonal
	def diagonal(i, j)
		i == j
	end

	# For iterators, select elements off diagonal
	def off_diagonal(i, j)
		i != j
	end

	# For iterators, select elements below diagonal and on diagonal
	def lower(i, j)
		i >= j
	end

	# For iterators, select elements below diagonal
	def strict_lower(i, j)
		i > j
	end

	# For iterators, select elements above diagonal and on diagonal
	def upper(i, j)
		i <= j
	end

	# For iterators, select elements above diagonal
	def strict_upper(i, j)
		i < j
	end

	# Select elements with indices based on selector
	public
	def each_with_index(selector=:all)
		return to_enum(:each_with_index, selector) unless block_given?
		send(@@iterators[selector], &Proc.new)
	end

	# Select elements based on selector
	def each(selector=:all)
		return to_enum(:each, selector) unless block_given?
		each_with_index(selector){ |x, i, j| yield x }
	end

	# Return indices if result exists
	protected
	def indices_or_nil(result)
		result.nil? ? nil : result[1..2]
	end

	# Return index in matrix of value
	def index_of_value(value, selector)
		index_of_block(selector){ |x| x == value }
	end

	# return index in matrix where block equals true
	def index_of_block(selector)
		indices_or_nil(each_with_index(selector).find{ |x, i, j| yield x })
	end

	@@index_finders = {
		1 => :index_of_block,
		2 => :index_of_value
	}

	# Return index where block is true
	public
	def index(*args, &block)
		return to_enum(:index) unless block_given?
		send(index_finders[args.length], *args, &block)
	end

	override :find_index, :index

	# Make new matrix based on selector and passed block
	def map(selector=:all)
		# TODO: Use smart matrix builder
		# In this case, it might also make sense to choose a builder
		# based on the selector.
		MatrixBuilder.create(:complete, row_size, column_size) { |builder|
			each_with_index(selector) { |x, i, j| builder[i, j] = yield x }
		}.to_mat
	end

	override :collect, :map

	##############
	# Properties #
	##############

	# Return unique pairs of rows. Useful for property checks
	protected
	def unique_row_pairs
		return to_enum(:unique_row_pairs) unless block_given?
		# NOTE: For matrices which create rows on demand, rows
		# are being created multiple times.  This can be optimized
		# by creating each row vector only once.
		rows.each_with_index.all? { |row, i|
			i.upto(@row_size - 1) { |j| yield row, row(j), i, j }
		}
	end

	# Check if matrix is diagonal
	public
	def diagonal?
		lower_triangular? && upper_triangular?
	end

	# Check if matrix is normal
	def normal?
		# NOTE: Now the column vectors are being created
		# every time.  This can be optimized by creating them
		# only once.
		unique_row_pairs.all? { |row_i, row_j, i, j|
			row_i * row_j.conj == column(i).conj * column(j)
		}
	end

	# Check if matrix is orthogonal
	def orthogonal?
		unique_row_pairs.all? { |row_i, row_j, i, j|
			row_i * row_j == (i == j ? 1 : 0)
		}
	end	

	# Check if matrix is unitary
	def unitary?
		unique_row_pairs.all? { |row_i, row_j, i, j|
			row_i * row_j.conj == (i == j ? 1 : 0)
		}
	end

	##############
	# Arithmetic #
	##############

	# Multiply matrix by matrix
	protected
	def matrix_multiply(mat)
		# NOTE: Column vectors created repeatedly could be slow.
		# TODO: Use smart matrix builder.
		MatrixBuilder.create(:complete, row_size, mat.column_size) { |b|
			rows.each.with_index { |row, i|
				mat.column_size.times { |j|
					b[i, j] = row * mat.column(j)
				}
			}
		}.to_mat
	end

	# Multiply matrix by vector
	def vector_multiply(vec)
		# TODO: Use smart vector builder
		VectorBuilder.create(:complete, vec.size) { |builder|
			rows.each.with_index { |row, i| builder[i] = row * vec }
		}.to_vec
	end

	# Multiply matrix by scalar (numeric)
	def scalar_multiply(x)
		map{ |y| x * y }
	end

	@@multipliers = OverloadTable.new({
		MatrixContract => :matrix_multiply,
		VectorContract => :vector_multiply,
		Numeric => :scalar_multiply
	})

	# Multiply matrix by argument
	public
	def *(x)
		return apply_through_coercion(x, :*) unless @@multipliers.include?(x)
		send(@@multipliers.select(x), x)
	end

	# Divide matrix by matrix
	protected
	def matrix_divide(mat)
		matrix_multiply(mat.inverse)
	end

	# Divide matrix by scalar (numeric)
	def scalar_divide(x)
		map{ |y| y / x }
	end

	@@dividers = OverloadTable.new({
		MatrixContract => :matrix_divide,
		Numeric => :scalar_divide
	})

	# Divide matrix by argument
	public
	def /(x)
		return apply_through_coercion(x, :/) unless @@dividers.include?(x)
		send(@@dividers.select(x), x)
	end

	# Add matrix to self
	protected
	def matrix_add(mat)
		# TODO: use smart matrix builder
		MatrixBuilder.create(:complete, row_size, column_size) { |builder|
			each_with_index { |x, i, j| builder[i, j] = x + mat[i, j] }
		}.to_mat
	end

	# Add vector to self
	def vector_add(vec)
		matrix_add(vec.covector.transpose)
	end

	@@adders = OverloadTable.new({
		MatrixContract => :matrix_add,
		VectorContract => :vector_add
	})

	# Add argument to self
	public
	def +(x)
		return apply_through_coercion(x, :+) unless @@adders.include?(x)
		send(@@adders.select(x), x)
	end

	# Subtract argument from self
	def -(x)
		return apply_through_coercion(x, :-) unless @@adders.include?(x)
		self + -x
	end

	# Take matrix to positive integer exponent through the use of
	# the binary representation of the integer number.
	protected
	def positive_integer_exponent(power)
		power.to_s(2).length.times.unfold(self){ |m| m * m }
			.zip(power.to_s(2).split("").reverse)
			.select{ |m, c| c == "1" }.map{ |m, c| m}
			.reduce(:*)
	end

	# Matrix to power of 0
	def zero_integer_exponent(power)
		# TODO: Use an optimized class for the identity matrix
		Matrix.identity(row_size)
	end

	# Matrix to power of negative integer
	def negative_integer_exponent(power)
		inverse ** power
	end

	@@integer_exponents = OverloadTable.new({
		-Float::INFINITY..-1 => :negative_integer_exponent,
		0 => :zero_integer_exponent,
		1..Float::INFINITY => :positive_integer_exponent
	})

	# Matrix to power of integer exponent
	def integer_exponent(power)
		send(@@integer_exponents.select(power), power)
	end

	# Matrix to power of non-integer exponent
	def numeric_exponent(power)
		# TODO: this is copied from Matrix.  Either rewrite it, getting
		# rid of the temporary variables, or forward it to Matrix somehow.
		v, d, v_inv = eigensystem
		v * Matrix.diagonal(*d.each(:diagonal).map{ |e| e ** other }) * v_inv
	end

	@@exponents = OverloadTable.new({
		Integer => :integer_exponent,
		Numeric => :numeric_exponent
	})

	# matrix to power of argument
	public
	def **(x)
		return apply_through_coercion(x, :**) unless @@exponents.include?(x)
		send(@@exponents.select(x), x)
	end

	override :+@, :clone

	# Return matrix but every element is timesed by -1
	def -@
		map(&:-@)
	end

	############
	# Equality #
	############

	# Determine matrix equality
	def ==(other)
		other.is_a?(MatrixContract) &&
		other.row_size == row_size &&
		other.column_size == column_size &&
		zip(other).all? { |x, y| x == y }
	end

	# Determine implementation equality
	def eql?(other)
		other.class == self.class &&
		other.row_size == row_size &&
		other.column_size == column_size &&
		zip(other).all? { |x, y| x.eql?(y) }
	end

	####################
	# Matrix Functions #
	####################

	override :det, :determinant
	override :tr, :trace
	override :t, :transpose

	##################
	# Decompositions #
	##################

	override :eigen, :eigensystem
	override :lup_decomposition, :lup

	######################
	# Complex Arithmetic #
	######################

	override :conj, :conjugate
	override :imag, :imaginary
	override :rectangular, :rect

	##############
	# Conversion #
	##############

	# Coerce numeric into scalar
	def coerce(value)
		[Scalar.new(value), self]
	end

	# Convert matrix to array
	def to_a
		rows.map(&:to_a)
	end

	# Convert matrix to string
	def to_s
		"#{self.class}[#{rows.map{ |row| row.to_a.to_s }.join(', ')}]"
	end

	override :inspect, :to_s
end
