{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "steam";
	namespace = [ "programs" ];

	inherits = [ "application" ];	

	variable =
	{ variable, meta, ... }:
	{
		
		program.actions.default.arguments =
		[
			"-tenfootui"
		];

		type = "cli";

	};

	output.config =
	{ variable, ... }:
	{
		programs.steam =
		{
			enable = true;
			package = variable.program.package.final;
		};
	};

}
