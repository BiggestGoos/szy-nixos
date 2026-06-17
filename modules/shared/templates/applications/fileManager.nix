{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "fileManager";

	extends = [ "defaultApplication" ];

}
