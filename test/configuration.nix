{ lib, szy, ... }:
{

	config.nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

}
