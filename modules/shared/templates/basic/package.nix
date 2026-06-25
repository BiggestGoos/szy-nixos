{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "package";

	/*
		The idea is that you set the package value to e.g. pkgs.neovim, etc...
		Then all thing that want to search in that package, e.g. desktopEntry and program.
		Then if you want to override the package, e.g. with desktopEntry, then you set, 
		finalPackage to that override and then, e.g. programs.neovim.package to finalPackage.
	*/
	parameters =
	{ final, template }:
	{

		package = lib.options.mkOption
		{
			type = lib.types.package;
			default = 
			let
				name = final.meta.name;
				program = config.programs."${name}" or {};
				service = config.services."${name}" or {};

				package = pkgs."${name}" or ("No package with name { ${name} }");
			in
				package;
		};

		finalPackage = lib.options.mkOption
		{
			type = lib.types.package;
			default = final.data.package;
		};

	};

}
