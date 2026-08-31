{ szy, config, lib, ... }:
let
	defaultName = "default";
in
(szy config).objects.make.template
{

	name = "program";

	inherits =
	[
		"package"
		"commands"
	];

	schema =
	{
		package = "package";
		commands = "commands";
	};

	variable' =
	{ variable, ... }:
	{

		bin = lib.options.mkOption
		{
			type =
			let
				binPath = lib.types.str // 
				{
					name = "existing path";
					check = (path: builtins.pathExists path);
				};
			in
				lib.types.attrsOf binPath;
			default = {};
		};

		actions = lib.options.mkOption
		{
			type =
			let
				module.options =
				{
					bin = lib.options.mkOption
					{
						type = 
						let
							bins = builtins.attrNames variable.bin;
						in
							lib.types.enum bins;
						default = defaultName;
					};

					arguments = lib.options.mkOption
					{
						type = lib.types.listOf lib.types.str;
						default = [];
					};
				};
			in
				lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });
		};

	};

	variable =
	{ variable, meta, ... }:
	{
		
		bin.${defaultName} =
		let
			package = variable.package.final;
			mainProgram = if package.meta ? "mainProgram" then lib.meta.getExe package else null;
			naive = lib.meta.getExe' package (lib.lists.last meta.identifier);
			program = if mainProgram != null then mainProgram else naive;
		in
		lib.mkIf (package != null && (builtins.pathExists program)) program;
		
		actions.${defaultName} = {};

		commands =
		lib.attrsets.mapAttrs
		(
			name: value:
			let
				absolute = variable.bin."${value.bin}";
				relative = builtins.baseNameOf absolute;
				inherit (value) arguments;
			in
			{
				relative = lib.strings.concatStringsSep " " ([ relative ] ++ arguments);
				absolute = lib.strings.concatStringsSep " " ([ absolute ] ++ arguments);
			}
		) variable.actions;

	};

}
