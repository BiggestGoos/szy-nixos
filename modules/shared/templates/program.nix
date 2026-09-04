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
	};

	variable' =
	{ variable, ... }:
	{

		/*
			A dictionary of bin-names to bin-paths
		*/
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

		/*
			A dictionary of "actions". An action consists of the name of a bin and a list of arguments
		*/
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
	{ variable, constant, meta, ... }:
	{
		
		# Tries to find the default bin path
		bin.${defaultName} =
		let
			package = constant.package.final;
			mainProgram = if package.meta ? "mainProgram" then lib.meta.getExe package else null;
			naive = lib.meta.getExe' package (lib.lists.last meta.identifier);
			program = if mainProgram != null then mainProgram else naive;
		in
		lib.mkIf (package != null && (builtins.pathExists program)) program;
		
		# All programs have a default action
		actions.${defaultName} = {};

	};

	absolute.variable =
	{ getFrom, ... }:
	let
		program = getFrom "variable" "program";
	in
	{

		/*
			This will create commands from all of the actions of the program
		*/
		commands =
		lib.attrsets.mapAttrs
		(
			name: value:
			let
				absolute = program.bin."${value.bin}";
				relative = builtins.baseNameOf absolute;
				inherit (value) arguments;
			in
			{
				relative = lib.strings.concatStringsSep " " ([ relative ] ++ arguments);
				absolute = lib.strings.concatStringsSep " " ([ absolute ] ++ arguments);
			}
		) program.actions;

	};

}
