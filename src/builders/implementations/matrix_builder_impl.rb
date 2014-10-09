require_relative '../vector_builder'

# Derived class must implement to_mat, indicating how the builder
# will be transformed into a matrix, and builder_type, indicating
# which underlying VectorBuilder to use.  Additionally, the derived
# class must register itself by calling register with a symbol.
class MatrixBuilderImpl
	include Enumerable
	
	# Return the array of registered builders. For use with decorator.
	def self.builders
		@@builders
	end
	
	@@builders = {}

	# Derived classes call this to register themselves so that they can be
	# made through the MatrixBuilder's create method
	def self.register(type)
		@@builders[type] = self
	end
	private_class_method :new

	# Optimizes the storage of sparse vectors by creating
	# vectors only when necessary, and abstracts the sparsity
	# by returning zeros and empty vector builders when the
	# key is not found.
	class VectorBuilderHash < Hash
		# Creates a VectorBuilderHash of vectors of the given type
		def initialize(builder_type, builder_size)
			super()

			@builder_size = builder_size
			@builder_type = builder_type
			@empty_builder = VectorBuilder.create(
				builder_type, builder_size
			)
		end

		#TODO: Make this work properly
		#def initialize_copy(other)
		#	@builder_size = other.builder_size
		#	@empty_builder = other.empty_builder
		#	@builder_type = other.builder_type
		#	other.each{ |k, v| super_set(k, v) }
		#end

		protected
		attr_reader :builder_size
		attr_reader :empty_builder

		public
		alias super_get []
		alias super_set []=

		# Accesses element [i,j] of the VectorBuilderHash
		def [](i, j)
			include?(i) ? super(i)[j] : 0
		end

		# Sets element [i,j] of the VectorBuilderHash
		def []=(i, j, v)
			super_set(i, VectorBuilder.create(
				@builder_type, @builder_size
			)) unless include?(i)

			super_get(i)[j] = v
		end

		# Returns the vector representing the ith row.
		def row(i)
			super_get(i) || @empty_builder
		end
	end

	# Creates a new matrix of row_size and column_size for the given builder_type
	def initialize(row_size, column_size)
		@row_size = row_size
		@column_size = column_size
		@rows = VectorBuilderHash.new(builder_type, column_size)

		yield self if block_given?
	end

	# Creates a copy of the matrix passed.
	def initialize_copy(other)
		@row_size = other.row_size
		@column_size = other.column_size
		@rows = other.rows.dup
	end

	protected
	attr_reader :rows

	public
	attr_reader :row_size
	attr_reader :column_size

	# Access element [i,j] of the matrix
	def [](i, j)
		@rows[i, j]
	end

	# Set element [i,j] of the matrix
	def []=(i, j, value)
		if value != 0 && i >= 0 && i < row_size && j >= 0 && j < column_size
			@rows[i, j] = value
		end
	end

	# Check if other is equal to self
	def ==(other)
		other.kind_of?(MatrixBuilderContract) &&
		row_size == other.row_size &&
		column_size == other.column_size &&
		zip(other).all?{ |x, y| x == y }
	end

	# Iterate over values and indices in the MatrixBuilder
	def each_with_index
		return to_enum(:each_with_index) unless block_given?
		row_size.times{ |i| column_size.times{ |j| yield self[i, j], i, j }}
	end

	# Iterate over values in the MatrixBuilder
	def each
		return to_enum(:each) unless block_given?
		each_with_index{ |x, i, j| yield x }
	end
end
