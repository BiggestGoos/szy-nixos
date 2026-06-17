{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "application";

	extends = [ "program" "desktopEntry" ];

	parameters =
	{ final, template }:
	{

		application = 
		{

			type = lib.options.mkOption
			{
				type = 
				let
					types = 
					[
						"gui"
						"cli"
						"both"
					];
				in
					lib.types.enum types;
			};

		};

	};

	defaultArguments =
	{ final, template }:
	let
		inherit (final.data.application) type;

		defaultRun =
		if (type == "cli")
		then final.data.program.arguments.exec
		else final.data.program.arguments.open;

	in
	{

		program.arguments.exec = lib.mkIf (type != "gui") {};
		program.arguments.open = lib.mkIf (type != "cli") {};

		program.arguments.defaultDesktopEntry =
		{
			generateCommand = false;
			args = 
			let

				old = final.data.desktopEntry.default.base.values;

				oldArgs = if (old ? exec) then lib.lists.drop 1 (lib.strings.splitString " " old.exec) else [];
				newArgs = final.data.program.bin."${defaultRun.exe}".defaultArgs;
				combined = lib.lists.unique (newArgs ++ oldArgs);

			in
				combined;
		};
		
		desktopEntry.default.base.path = lib.mkIf (type != "cli") (lib.mkDefault final.meta.name);
		desktopEntry.default.overrides =
		let

			inherit (final.data.program.arguments.defaultDesktopEntry) args;

			cmdline = lib.strings.concatStringsSep " " ([ final.data.program.bin."${defaultRun.exe}".name ] ++ args);

		in
		lib.mkIf ((type != "cli") && (final.data.desktopEntry.default.base.values != {}))
		{
			exec = lib.mkDefault cmdline;
		};

	};

	configuration =
	{ enabled, final }:
	{

		imports =
		[
			./applications.nix
		];

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
				let
					inherit (definition.data.application) type;
				in
				[
					{
						assertion = (type == "gui") || definition.data.commands ? exec;
						message = "The cli definition \"${definition.meta.name}\" of the template \"${definition.meta.template}\" must have an exec command value!";
					}
					{
						assertion = (type == "cli") || definition.data.commands ? open;
						message = "The gui definition \"${definition.meta.name}\" of the template \"${definition.meta.template}\" must have an open command value!";
					}
				]
			)
			definitions
		);

	};

}
