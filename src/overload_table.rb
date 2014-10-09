class OverloadTable
	def initialize(overloads)
		@overloads = overloads
	end

	def select(value)
		@overloads.find{ |type, _| type === value }[1]
	end

	def include?(value)
		@overloads.any?{ |k, _| k === value }
	end
end
