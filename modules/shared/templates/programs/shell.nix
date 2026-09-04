{ szy, lib, config, pkgs, ... }:
(szy config).objects.make.template
{
	
	name = "basic";
	namespace = [ "programs" "shell" ];

	inherits = [ "application" ];
	propagates = [ "default" ];

	variable =
	{

		program.actions =
		{
			runCommand = {};
			interactive = {};
		};

	};

}
