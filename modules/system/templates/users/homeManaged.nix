{ szy, config, lib, ... }:
let
	szy' = szy config;
in
szy'.objects.declare
{

	name = "homeManagedUser";

	parameters =
	{

		paths = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.path;
		};

	};

}
