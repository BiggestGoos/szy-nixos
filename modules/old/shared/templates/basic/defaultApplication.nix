{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "defaultApplication";

	extends = [ "application" "default" ];

	qualifiers =
	[
		{
			name = "generateTemplateOptions";

			arguments =
			{
				namespace = [ "catalog" "applications" "defaults" ];

				#readOnly = true;

				determineOption = template:
				let
					inherit (template.data) default;
					names = builtins.attrNames template.meta.metaData.defaultTypes;
				in
				{

					type = 
					let

						module = name:
						{
							options."${name}" = lib.options.mkOption
							{
								type = lib.types.submodule
								{
									freeformType = lib.types.anything;
									options.value = szy.lib.options.constant
									{
										type = lib.types.nullOr lib.types.attrs;
										value = default."${name}".value.data or null;
									};
								};	
							};
						};

					in
					lib.types.submoduleWith 
					{ 
						modules =
						builtins.map
						(
							name: 
								module name
						) names;
					};

				};

				determineData = template: data:
				{
					default =
					lib.attrsets.mapAttrs
					(
						name: value:
						if (value ? identifier)
						then
						{
							inherit (value) identifier;
						}
						else {}
					) data;
				};

			};
		}
	];

	defaultMetaArguments.template =
	{ final }:
	{

		defaultTypes = 
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
	if (szy.data.configType == "system")
	then
	{}
	else if (szy.data.configType == "user")
	then
	{

		/*xdg.mimeApps = Fix to use new catalog stuff!
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
					default.finalPackage
			)
			defaults;

		};*/

	}
	else
	{};

}
