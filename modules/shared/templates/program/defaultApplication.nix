{ szy, lib, config, pkgs, systemConfig, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "defaultApplication";

	extends = [ "application" "default" ];

	templateArguments =
	{ final }:
	{

		defaultTypes = 
		lib.mkDefault
		{
			any = definition:
			let
				inherit (definition.meta) identifier;
				guiIdentifier = final.data.default.gui.identifier;
				cliIdentifier = final.data.default.cli.identifier;
			in
				(identifier == guiIdentifier) || (identifier == cliIdentifier);
			gui = definition: definition.data.application.type != "cli";
			cli = definition: definition.data.application.type != "gui";
		};

	};

	configuration =
	{ enabled, final }:
	if (systemConfig)
	then
	{
	}
	else
	{

		xdg.mimeApps =
		{

			enable = true;

			defaultApplicationPackages =
			let
				inherit (config."${szy}".applications) default;

				rawDefaults =
				lib.attrsets.mapAttrsToList
				(
					name: value:
						value.any
				)
				default;

				defaults =
				builtins.filter
				(
					default:
						default != null
				)
				rawDefaults;
			in
			builtins.map
			(
				default:
					default.package
			)
			defaults;

		};

	};

}
