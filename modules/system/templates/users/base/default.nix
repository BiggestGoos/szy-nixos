{ szy, lib, config, pkgs, ... }:
let

	szy' = szy config;

	types =
	{
		normal = "normal";
		system = "system";
	};

	isHomeManaged = user: (config ? home-manager) && (config.home-manager ? "${user}");

	systemShell = szy'.objects.utils.template.get { identifier = "shell"; };
	userShell = user: 
	if (isHomeManaged user)
	then szy.objects.utils.template.get { identifier = "shell"; config = config.home-manager.users."${user}"; }
	else {};

	defaultSystemShell = (systemShell.data.default.cli.value.data or {}).finalPackage or null;
	defaultUserShell = user: 
	let
		shell = userShell user;
	in
	if (shell == {})
	then null
	else (shell.data.default.cli.value.data or {}).finalPackage or null;

in
szy'.objects.declare
{
	
	name = "user";

	parameters =
	{ final, template, ... }:
	{

		# All definitions extending user MUST have a unique name, not just per template
		username = szy.lib.options.constant
		{
			type = lib.types.str;
			value = final.meta.name;
		};

		homeDirectory = lib.options.mkOption
		{
			type = lib.types.str;
			default =
			let
				base = lib.strings.removeSuffix "/" config.users.defaultUserHome;
			in
				"${base}/${final.data.username}";
		};

		shell = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = defaultUserShell final.data.username;
		};

		types = lib.options.mkOption
		{
			type = lib.types.listOf (lib.types.enum (builtins.attrNames template.data.types));
			default = template.data.defaultTypes;
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
						template.data.types."${type}".groups
				) final.data.types;
				addGroups = builtins.concatLists ([ final.data.extraGroups ] ++ typesGroups);
			in
			lib.lists.unique 
			(
				lib.lists.subtractLists
				final.data.removeGroups
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

	templateParameters =
	{ final, ... }:
	{

		defaultShell = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = defaultSystemShell;
		};

		defaultTypes = lib.options.mkOption
		{
			type = lib.types.listOf (lib.types.enum (builtins.attrNames final.data.types));
		};

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

	templateArguments =
	{ final, ... }:
	{
		
		defaultTypes = lib.mkDefault [ types.normal ];

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

	configuration =
	{ final, ... }:
	let
		users =
		builtins.map
		(
			identifier:
				szy'.objects.utils.definition.get { inherit identifier; }
		) final.meta.full.definitions;
	in
	{

		imports = szy.lib.imports.propagate.list { inherit types users; }
		[
			./users.nix
		];

		assertions =
		[
			{
				assertion = 
				lib.lists.all
				(
					user:
						user.data.homeDirectory == config.users.users."${user.data.username}".home
				) users;
				message = "All user's homeDirectory value must match config.users.users.<name>.home. Currently at least one user doesn't fulfill this!";
			}
		];

	};

}
