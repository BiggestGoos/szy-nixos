{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "editor";

	extends = [ "defaultApplication" ];

	configuration =
	{ enabled, final }:
	let

		default = final.data.default.any.value;
		defaultOpen = (default.data.commands.exec or default.data.commands.open).relative;

		scriptName = "${szy}+defaultEditor";
		script = pkgs.writeShellScriptBin scriptName
''
exec ${defaultOpen} "$@"
'';

	in
	{
		"${szy}" =
		{
			variables =
			{
				EDITOR = lib.mkDefault
				{
					value = scriptName;
					override = "force";
				};
				VISUAL = lib.mkDefault
				{
					value = scriptName;
					override = "force";
				};
			};
			packages = [ script ];
		};
	};

}
