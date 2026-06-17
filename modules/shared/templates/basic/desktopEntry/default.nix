{ szy, lib, config, pkgs, system, systemConfig, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "desktopEntry";

	parameters = import ./parameters.nix { inherit szy lib pkgs; };

	configuration =
	{ enabled, final }:
	let

		definitions = builtins.map (identifier: szy.objects.helper.definition.get ({ inherit config identifier; })) final.meta.full.definitions;
		enabledDefinitions = builtins.filter
		(
			definition:
				definition.data.enabled
		)
		definitions;

		flatList =
		lib.lists.flatten
		(
			builtins.map
			(
				definition:
				lib.attrsets.mapAttrsToList
				(
					name: value:
						value
				)
				definition.data.desktopEntry
			)
			enabledDefinitions	
		);

		filteredList = builtins.filter
		(
			entry:
				entry.final.path != null
		)
		flatList;

		argsList =
		builtins.map
		(
			desktopEntry:
''
install -D -m 664 ${desktopEntry.final.path} $out/share/applications/${desktopEntry.final.values.name}.desktop
''
		)
		filteredList;

		argsStrBase = 
''
export PATH="$coreutils/bin"

mkdir $out
mkdir -p $out/share/applications
'';

		argsStr = lib.strings.concatStrings ([ argsStrBase ] ++ argsList);

		package = builtins.derivation
		{
			name = "desktopEntryOverrides";
			inherit system;
			builder = "${pkgs.bash}/bin/bash";

			coreutils = pkgs.coreutils;

			args = 
			[
				(
					pkgs.writeScript "makeDesktopEntryOverrides" argsStr
				)
			];

		};

		prioritizedPackage = lib.meta.setPrio (-999999999) package;

	in
	{
		"${szy}".packages = [ prioritizedPackage ];
	};

}
