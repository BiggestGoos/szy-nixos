{ szy, config, lib, ... }:
let
	szy' = szy config;
in
szy'.objects.declare
{

	name = "homeManagedUser";

	parameters =
	{

		path = lib.options.mkOption
		{
			type = lib.types.path;
		};

	};

}
