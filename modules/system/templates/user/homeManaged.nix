{ szy, lib, config, pkgs, ... }:
(szy config).objects.make.template
{
	
	name = "homeManaged";
	namespace = [ "user" ];

	variable' =
	{

		# Imported by the users home-manager
		modules = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.anything;
		};

	};

}
