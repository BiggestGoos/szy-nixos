{ lib, szy, ... }:
{

	nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

	"${szy}".objects =
	{
		applications.steam.variable =
		{
			enable = true;
			bigPicture = false;
		};
	};

}
