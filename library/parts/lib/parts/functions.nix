{ lib, ... }:
{

	content =
	{

		# Whether or not a given value is a function or functor
		isCallable = value: (builtins.isFunction value) || ((builtins.isAttrs value) && (value ? __functor));

		# Resolve a value, either it is a function to value or just value.
		resolveValue = value: argument: (lib.trivial.toFunction value) argument;

	};

}
