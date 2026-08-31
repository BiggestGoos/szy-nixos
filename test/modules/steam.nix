{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "steam";
	namespace = [ "programs" ];

	inherits = [ "application" ];	

	variable =
	{ variable, meta, ... }:
	{
		
		actions.default.arguments =
		[
			"-tenfootui"
		];

		desktopEntry.default.base =
		{
			path = lib.lists.last meta.identifier;
			package = variable.package.input;
		};

	};

	output.config =
	{ variable, ... }:
	{
		programs.steam =
		{
			enable = true;
			package = variable.package.final;
		};
	};

}
