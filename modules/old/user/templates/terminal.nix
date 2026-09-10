{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "terminal";

	extends = [ "defaultApplication" ];

	metaArguments =
	{ final }:
	{

		defaultTypes = 
		{
			gui = definition: true;
			any = definition: definition.meta.identifier == final.data.default.gui.identifier;
		};

	};

	defaultArguments =
	{ final, template }:
	{

		application.type = lib.mkForce "gui";

		program.arguments =
		{
			runCommand.required = lib.mkForce true;
			remainOpen =
			{
				required = lib.mkForce true;
				generateCommand = false;
			};
			setDirectory =
			{
				required = lib.mkForce true;
				generateCommand = false;
			};
			setAppID =
			{
				required = lib.mkForce true;
				generateCommand = false;
			};
			setTitle =
			{
				required = lib.mkForce true;
				generateCommand = false;
			};
		};

		desktopEntry._default =
		{
			overrides =
			{
				extraConfig =
				let
					inherit (final.data.program) arguments;
					values =
					{
						"X-TerminalArgExec" = arguments.runCommand;
						"X-TerminalArgHold" = arguments.remainOpen;
						"X-TerminalArgDir" = arguments.setDirectory;
						"X-TerminalArgAppId" = arguments.setAppID;
						"X-TerminalArgTitle" = arguments.setTitle;
					};
				in
				lib.attrsets.mapAttrs
				(
						name: value:
							lib.strings.concatStringsSep " " value.args
				)
				values;
			};		
		};
		
		desktopEntry.runCommand =
		{

			required = lib.mkForce true;

			overrides = 
			{
				categories = [ "TerminalEmulator" ];
				exec = lib.mkDefault final.data.commands.open.relative;
				name = lib.mkDefault "${final.meta.name}/runCommand";
				noDisplay = true;
				desktopName = "${final.meta.name}-runCommand";
			};

		};

	};

	configuration =
	{ enabled, final }:
	let
		default = final.data.default.any.value;
		defaultOpen = default.data.commands.open.relative;
		defaultRunCommand = default.data.commands.runCommand.relative;

		scriptName = "${szy}+defaultTerminal";
		script = pkgs.writeShellScriptBin scriptName
''
first=$1

if [[ "$first" == */* ]]; then
    # Explicit path
    if [[ -f "$first" && -x "$first" ]]; then
        exec ${defaultRunCommand} "$@"
    fi
else
    # Command in PATH
    if type -P -- "$first" >/dev/null 2>&1; then
        exec ${defaultRunCommand} "$@"
    fi
fi

exec ${defaultOpen} "$@"
'';
		
	in
	{

		xdg.terminal-exec =
		{
			enable = true;
			settings =
			{
				default = 
				[
					default.data.desktopEntry.runCommand.final.id
				];
			};
		};

		"${szy}" =
		{
			variables.TERMINAL =
			{
				value = scriptName;
				override = "force";
			};
			packages = [ script ];
		};

	};

}
