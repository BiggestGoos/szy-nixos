{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "shell";

	extends = [ "defaultApplication" "terminalApplication" ];

	defaultArguments =
	{ final, template }:
	{

		program.arguments =
		{
			runCommand.required = true;
			interactive.required = true;
		};

	};

}
