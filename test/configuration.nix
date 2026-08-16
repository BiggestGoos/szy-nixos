{ lib, szy, ... }:
{

	nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

	"${szy}".catalog.applications =
	{
		steam.enable = true;
	};

}
