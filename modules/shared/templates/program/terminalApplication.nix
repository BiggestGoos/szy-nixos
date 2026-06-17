{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "terminalApplication";

	parameters =
	{ final, template }:
	{

		application =
		{

			terminal =
			let
				terminals = (szy.objects.helper.getTemplate { inherit config; name = "terminal"; }).meta.full.definitions;

				names = builtins.map (identifier: identifier.name) terminals;
				templates = builtins.map (identifier: identifier.template) terminals;

				inherit (final.data.application) terminal;
			in
			lib.options.mkOption
			{
	
				type = 
				let

					module.options =
					{

						name = lib.options.mkOption
						{
							type = lib.types.enum names;
						};

						template = lib.options.mkOption
						{
							type = lib.types.enum templates;
							default =
							let
								inherit (terminal) name;

								possibleDefinitions =
								builtins.filter 
								(
									identifier: identifier.name == name
								) terminals;

								template =
								lib.trivial.throwIfNot
								(
									(builtins.length possibleDefinitions) == 1
								)
								"Either there is no terminal with name ${name} or you also need to specify which template it defines"
								(
									(builtins.head possibleDefinitions).template
								);
							in
								template;
						};

					};

				in
					lib.types.nullOr (lib.types.submoduleWith { modules = [ module ]; });

				default = null;

			};

		};

	};

	defaultArguments =
	{ final, template }:
	let
		inherit (final) data;
		inherit (data) application desktopEntry;
		inherit (application) terminal type;

		runCommand = (szy.objects.helper.definition.get ({ inherit config; identifier = terminal; })).data.commands.runCommand.relative;
	in
	{

		application.type = 
		if (terminal == null)
		then lib.mkDefault "cli"
		else lib.mkForce "both";

		desktopEntry.default.overrides =
		lib.mkIf (terminal != null)
		{
			terminal = lib.mkDefault false;
			exec = 
			let
				inherit (final.data.program.arguments.defaultDesktopEntry) args;

				cmdline = lib.strings.concatStringsSep " " ([ runCommand final.data.program.bin."${final.data.program.arguments.open.exe}".name ] ++ args);
			in
			lib.mkOverride 999 cmdline;
		};

		commands.open =
		let
			inherit (final.data.program) arguments bin;

			openExe = bin."${arguments.open.exe}";

			generateCommand = exe: "${lib.strings.concatStringsSep " " ([ exe ] ++ openExe.defaultArgs ++ arguments.open.args)}";

			defaultRunCommand = config."${szy}".applications.default.terminal.any.commands.runCommand.relative;
		in
		lib.mkIf (type != "cli")
		(if (terminal != null)
		then
		{
			absolute = lib.mkForce ("${runCommand} ${generateCommand openExe.path}");
			relative = lib.mkForce ("${runCommand} ${generateCommand openExe.name}");
		}
		else
		{
			absolute = lib.mkForce ("${defaultRunCommand} ${generateCommand openExe.path}");
			relative = lib.mkForce ("${defaultRunCommand} ${generateCommand openExe.name}");
		});

	};

	configuration =
	{ enabled, final }:
	{

		assertions =
		let
			definitions = 
			builtins.map
			(
				identifier:
					szy.objects.helper.definition.get { inherit config identifier; }
			)
			final.meta.full.definitions;
		in
		lib.lists.flatten
		(
			builtins.map
			(
				definition:
				[
					{
						assertion = builtins.elem definition.data.application.type [ "cli" "both" ];
						message = "The definition \"${definition.meta.name}\" of the template \"${definition.meta.template}\" is marked as a terminalApplication and can't have the application type \"${definition.data.application.type}\".";
					}
				]
			)
			definitions
		);

	};

}
