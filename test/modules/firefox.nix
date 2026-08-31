{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "firefox";
	namespace = [ "programs" ];

	inherits = [ "application" ];	

	variable =
	{ variable, meta, ... }:
	{

		desktopEntry.default.base =
		{
			path = lib.lists.last meta.identifier;
			package = variable.program.package.input;
		};

	};

	output.config =
	{ variable, ... }:
	{
		programs.firefox =
		{
			enable = true;
			package = variable.program.package.final;
		};
	};

}
