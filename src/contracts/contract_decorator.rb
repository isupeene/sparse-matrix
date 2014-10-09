require_relative 'contract_symbols'

# The built-in triple-equals is below the level of ruby 'is_a?'
# We need to redefine it so that instances of our decorator will
# be recognized as instances of the implementation.
class Module
	def ===(x)
		x.is_a?(self)
	end
end

module ContractDecorator
	include ContractSymbols

	def initialize_impl(implementation)
		@implementation = implementation
	end

	def initialize(implementation)
		initialize_impl(implementation)
	end

	def initialize_clone(other)
		initialize_impl(other.implementation.clone)
	end

	def initialize_dup(other)
		initialize_impl(other.implementation.dup)
	end

	protected
	attr_accessor :implementation

	public
	def self.enable_contracts(bool)
		@@enable_contracts = bool
	end
	
	def self.enable_contracts?
		@@enable_contracts
	end
	
	@@enable_contracts = true

	@@evaluating_contracts = false

	def ==(other)
		@implementation == other
	end

	def class
		@implementation.class
	end

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
				@@evaluating_contracts = false
				result = @implementation.send(symbol, *args, &block)
				@@evaluating_contracts = true
			}
			return result
		else
			@@evaluating_contracts = false
			result = @implementation.send(symbol, *args, &block)
			@@evaluating_contracts = true
			return result
		end
	end

	def try_execute_postcondition(symbol, *args, &block)
		if @implementation.respond_to?(postcondition_name(symbol))
			@implementation.send(postcondition_name(symbol), *args, &block)
		end
	end

	def method_missing(symbol, *args, &block)
		if @@enable_contracts && !@@evaluating_contracts
			begin
				@@evaluating_contracts = true
				symbol = symbol.to_s
				try_execute_class_invariant
				try_execute_precondition(symbol, *args, &block)

				result = try_execute_method_invariant(symbol, *args, &block)

				try_execute_postcondition(symbol, *args << result, &block)
				try_execute_class_invariant

				return result
			ensure
				@@evaluating_contracts = false
			end
		else
			@implementation.send(symbol, *args, &block)
		end
	end
end
