{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "shellBase";

	extends = [ "defaultApplication" ];

	metaArguments =
	{
		generateTemplateOptions.generateOption = false;
	};
	
	defaultArguments =
	{ final, template }:
	{

		application.type = lib.mkForce "cli";

		program.arguments =
		{
			runCommand.required = true;
			interactive.required = true;
		};

	};

}
