{ szy, lib, config, pkgs, ... }:
let

	szy' = szy config;

	types =
	{
		normal = "normal";
		system = "system";
	};

	users = meta:
	builtins.filter
	(
		user:
			user.constant.enabled
	) 
	(
		builtins.map
		(
			identifier:
				szy'.objects.utils.get { inherit identifier; }
		) meta.allObjects
	);

in
szy'.objects.make.template
{
	
	name = "user";

	constant' =
	{ meta, ... }:
	{

		# All objects inheriting from user must hava a unique "name" (last element in identifier)
		username = szy.lib.options.constant
		{
			type = lib.types.str;
			value = lib.lists.last meta.identifier;
		};

	};

	variable' =
	{ variable, constant, ... }:
	{

		homeDirectory = lib.options.mkOption
		{
			type = lib.types.str;
			default =
			let
				base = lib.strings.removeSuffix "/" config.users.defaultUserHome;
			in
				"${base}/${constant.username}";
		};

		shell = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = 
			let
				user = constant.username;

				isHomeManaged = (config ? home-manager) && (config.home-manager ? "${user}");

				defaultUserShell = 
				let
					shell = 
					(
						(szy config.home-manager.users."${user}").objects.utils.get 
						{
							identifier = [ "template" "programs" "shell" ]; 
						}
					).constant.default.any;
				in
				if !isHomeManaged || shell == {}
				then null
				else shell.constant.program.package.final;
			in
				defaultUserShell;
		};

		types = lib.options.mkOption
		{
			type = lib.types.listOf (lib.types.enum (builtins.attrNames config."${szy}".users.types));
			default = [ types.normal ];
		};

		primaryGroup = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.str;
			default = null;
		};

		extraGroups = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
			default = [];
		};

		removeGroups = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
			default = [ ];
		};

		groups = szy.lib.options.constant
		{
			type = lib.types.listOf lib.types.str;
			value = 
			let
				typesGroups =
				builtins.map	
				(
					type:
						config."${szy}".users.types."${type}".groups
				) variable.types;
				addGroups = builtins.concatLists ([ variable.extraGroups ] ++ typesGroups);
			in
			lib.lists.unique 
			(
				lib.lists.subtractLists
				variable.removeGroups
				addGroups
			);
		};

		# Additional settings, directly merged into users.users.<name>
		settings = lib.options.mkOption
		{
			type = lib.types.attrs;
			default = {};
		};

	};

	output.options =
	{

		"${szy}".users =
		{

			# Types are basically groups of groups and default options for users.
			types = lib.options.mkOption
			{
				type = 
				let

					module.options =
					{

						groups = lib.options.mkOption
						{
							type = lib.types.listOf lib.types.str;
							default = [];
						};

						settings = lib.options.mkOption
						{
							type = lib.types.attrs;
							default = {};
						};

					};

				in
					lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });
				default = {};
			};

		};

	};

	output.config =
	{ meta, ... }:
	{

		"${szy}".users =
		{

			types."${types.normal}" = 
			{
				groups = [ "wheel" ];
			};

			types."${types.system}" = 
			{
				settings =
				{
					isSystemUser = true;
					isNormalUser = false;
				};
			};

		};

		assertions =
		[
			{
				assertion = 
				lib.lists.all
				(
					user:
						user.variable.homeDirectory == config.users.users."${user.constant.username}".home
				) (users meta);
				message = "All user's homeDirectory value must match config.users.users.<name>.home. Currently at least one user doesn't fulfill this!";
			}
		];

	};

	output.imports =
	{ meta, ... }:
	szy.lib.imports.propagate.list { inherit types; users = users meta; }
	[
		./internal/resolve.nix
	];

}
