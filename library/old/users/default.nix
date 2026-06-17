{ config, options, lib, nixpkgs, szy, ... }:
let

	userTypes = config."${options}".users.types.list;

in
{

	mkUser = 
	{ name, userType, shell ? null, extraGroups ? [], homeDirectory ? "/home", homeConfig ? null, configuration ? {}, imports ? [] }:
	let

		isNormalUser = assert (builtins.elem userType userTypes); if (userType == "normal" || userType == "guest") then true else false;

		groups = config."${options}".users.types.groups."${userType}";
		userGroups = config."${options}".users.declared."${name}".groups.extra;

		getDefaultShell = applications: ((applications.default or {}).shell or {}).cli or null;

		systemDefault = getDefaultShell config."${options}".applications;
		userDefault = getDefaultShell config.home-manager.users."${name}"."${options}".applications;

		resolvedShell = 
		if (shell != null) 
		then shell 
		else if (userDefault != null)
		then userDefault.package
		else if (systemDefault != null)
		then systemDefault.package
		else nixpkgs.runtimeShell;

		resolvedHomeDirectory = "${homeDirectory}/${name}";

	in
	{
	
		imports = szy.import.propogate {

			inherit name;

			home = resolvedHomeDirectory;

		} imports;
	
		config = {

			users.users."${name}" = {

				isNormalUser = isNormalUser;
				isSystemUser = !isNormalUser;

				extraGroups = groups ++ userGroups ++ extraGroups;

				shell = lib.mkIf (resolvedShell != null) resolvedShell;

				home = resolvedHomeDirectory;

			};

			"${options}".users.homeManagerPaths."${name}".path = lib.mkIf (homeConfig != null) homeConfig;

			home-manager.users."${name}" = {
				
				home = {
					username = name;
					homeDirectory = resolvedHomeDirectory;
				};

			};

		};

		options = {

			"${options}".users.declared."${name}" = {

				type = lib.mkOption {
					type = lib.types.enum userTypes;
					readOnly = true;
					default = userType;
				};

				shell = lib.mkOption {
					type = lib.types.package;
					readOnly = true;
					default = resolvedShell;
				};

				groups = {

					extra = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						default = [];
					};

					resolved = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						readOnly = true;
						default = [ config.users.users."${name}".group ] ++ config.users.users."${name}".extraGroups;
					};

				};

			};

		};

	};

}
