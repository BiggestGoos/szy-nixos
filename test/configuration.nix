{ lib, szy, ... }:
{

	nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

	"${szy}".objects.programs.steam.variable.enable = true;

}
