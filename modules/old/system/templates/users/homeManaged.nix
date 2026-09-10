{ szy, config, lib, ... }:
let
	szy' = szy config;
in
szy'.objects.declare
{

	name = "homeManagedUser";

	parameters =
	{

		# Imported by the users home-manager
		modules = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.anything;
		};

	};

}
