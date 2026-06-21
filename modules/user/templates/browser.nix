{ szy, lib, config, pkgs, ... }:
(szy config).objects.declare
{
	
	name = "browser";

	extends = [ "defaultApplication" ];

	defaultArguments =
	{ final, template }:
	{

		application.type = lib.mkDefault "gui";
		desktopEntry.default.required = lib.mkForce true;
		program.arguments.search.required = lib.mkForce true;

	};

	configuration =
	{ enabled, final }:
	let
	
		default = final.data.default.any.value;
		defaultOpen = default.data.commands.open.relative;
		
		scriptName = "${szy}+defaultBrowser";
		script = pkgs.writeShellScriptBin scriptName
''
exec ${defaultOpen} "$@"
'';

	in
	{
	
		xdg.mimeApps = 
		{

			enable = true;

			defaultApplications = 
			let
				mimetypes = 
				[
					"text/html"
					"x-scheme-handler/http"
					"x-scheme-handler/https"
					"x-scheme-handler/about"
					"x-scheme-handler/unknown"
				];
			in
			builtins.listToAttrs 
			(
				builtins.map 
				(
					mimetype: 
					{
						name = mimetype; 
						value = 
						[ 
							default.data.desktopEntry.default.final.id 
						]; 
					}
				)
				mimetypes
			);

		};

		"${szy}" =
		{
			variables = {
				BROWSER =
				{
					value = scriptName;
					override = "force";
				};
				DEFAULT_BROWSER =
				{
					value = scriptName;
					override = "force";
				};
			};
			packages = [ script ];
		};

	};

}
