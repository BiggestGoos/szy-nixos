{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "shell";

	extends = [ "shellBase" "terminalApplication" ];

}
