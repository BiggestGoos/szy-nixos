{ lib, ... }:
{

	content =
	{

		# Resolve a value, either it is a function to value or just value.
		resolveValue = value: argument: (lib.trivial.toFunction value) argument;

	};

}
