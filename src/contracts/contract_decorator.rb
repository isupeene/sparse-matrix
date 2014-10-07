require_relative 'contract_symbols'

module ContractDecorator
	include ContractSymbols

	def initialize(implementation)
		@implementation = implementation
	end

	attr_accessor :enable_contracts

	def try_execute_class_invariant
		if @implementation.respond_to?(:invariant)
			@implementation.invariant
		end
	end

	def try_execute_precondition(symbol, *args, &block)
		if @implementation.respond_to?(precondition_name(symbol))
			@implementation.send(precondition_name(symbol), *args, &block)
		end 
	end

	def try_execute_method_invariant(symbol, *args, &block)
		if @implementation.respond_to?(invariant_name(symbol))
			result = nil
			@implementation.send(invariant_name(symbol), *args) {
				result = @implementation.send(symbol, *args, &block)
			}
			return result
		else
			@implementation.send(symbol, *args, &block)
		end
	end

	def try_execute_postcondition(symbol, *args, &block)
		if @implementation.respond_to?(postcondition_name(symbol))
			@implementation.send(postcondition_name(symbol), *args, &block)
		end
	end

	def method_missing(symbol, *args, &block)
		if enable_contracts
			try_execute_class_invariant
			try_execute_precondition(symbol, *args, &block)

			result = try_execute_method_invariant(symbol, *args, &block)

			try_execute_postcondition(symbol, *args << result, &block)
			try_execute_class_invariant

			return result
		else
			@implementation.send(symbol, *args, &blocK)
		end
	end
end
