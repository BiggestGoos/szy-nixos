{ enabled, x, ... }:
{ lib, ... }:
{

	options =
	{

		x = lib.options.mkOption
		{
			type = lib.types.int;
			default = 5;
		};

	};

	config = enabled.enableIf
	{

		x = x;

	};

}
