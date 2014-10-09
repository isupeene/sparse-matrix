require_relative '../contracts/dumb_matrix_contract'

class DumbMatrixImpl

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?
	undef_method :class

	def initialize(builder)
		@builder = builder
		@impl = nil
		@dirty = true
	end

	def []=(i, j, value)
		builder[i, j] = value
		@dirty = true
	end

	def method_missing(symbol, *args, &block)
		if @dirty
			@impl = @builder.to_smart_mat
			@dirty = false
		end
		@impl.public_send(symbol, *args, &block)
	end

	include DumbMatrixContract
end
