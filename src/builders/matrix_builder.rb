require_relative 'vector_builder'

# Derived class must implement to_mat, indicating how the builder
# will be transformed into a matrix, and builder_type, indicating
# which underlying VectorBuilder to use.  Additionally, the derived
# class must register itself by calling register with a symbol.
class MatrixBuilder
	include Enumerable

	@@builders = {}

	def MatrixBuilder.create(type, *args, &block)
		@@builders[type].send(:new, *args, &block)
	end

	def self.register(type)
		@@builders[type] = self
	end

	private_class_method :new

	class VectorBuilderHash < Hash
		def initialize(builder_type, builder_size)
			super()

			@builder_size = builder_size
			@builder_type = builder_type
			@empty_builder = VectorBuilder.create(
				builder_type, builder_size
			)
		end

		alias super_get []
		alias super_set []=

		def [](i, j)
			include?(i) ? super(i)[j] : 0
		end

		def []=(i, j, v)
			super_set(i, VectorBuilder.create(
				@builder_type, @builder_size
			)) unless include?(i)

			super_get(i)[j] = v
		end

		def row(i)
			super_get(i) || @empty_builder
		end
	end

	def initialize(row_size, column_size)
		@row_size = row_size
		@column_size = column_size
		@rows = VectorBuilderHash.new(builder_type, column_size)

		yield self if block_given?
	end

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

	def [](i, j)
		@rows[i, j]
	end

	def []=(i, j, value)
		@rows[i, j] = value
	end

	def ==(other)
		other.kind_of?(MatrixBuilderContract) &&
		row_size == other.row_size &&
		column_size == other.column_size &&
		zip(other).all?{ |x, y| x == y }
	end

	def each_with_index
		return to_enum(:each_with_index) unless block_given?
		row_size.times{ |i| column_size.times{ |j| yield self[i, j], i, j }}
	end

	def each
		return to_enum(:each) unless block_given?
		each_with_index{ |x, i, j| yield x }
	end
end
