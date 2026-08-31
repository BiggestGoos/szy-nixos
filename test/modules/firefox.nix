{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "firefox";
	namespace = [ "programs" ];

	inherits = [ "application" ];	

	schema.application = "application";

	output.config =
	{ variable, ... }:
	{
		programs.firefox =
		{
			enable = true;
			package = variable.program.package.final;
		};
	};

	variable.application.type = "mix";

}
