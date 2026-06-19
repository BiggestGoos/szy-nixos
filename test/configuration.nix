{ lib, szy, ... }:
{

	options =
	{

		x = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
		};

	};

	imports = szy.lib.imports.toggled.recursive
	{
		enabled = true;
		withDefault = true;
		directory = ./modules;
	};

	/*imports = 
	[
		./modules/test1.nix
		./modules/foo/bar.nix
		./modules/123
		./modules/123/internal
		./modules/123/otherFolder
	];*/

}
