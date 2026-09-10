{ szy, config, lib, ... }:
let
	defaultName = "default";
	szy' = szy config;
in
szy'.objects.make.template
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

	qualifiers =
	[
		{
			name = "generateOptions";
			arguments =
			{
				namespace = [ szy "catalog" "programs" ];

				determine.objects = object: object.meta.allObjects;
			};
		}
		{
			name = "generateOptions";
			arguments =
			let
				defaultPath = object: (szy'.objects.utils.template.absolute.getPath object.meta.identifier "default") ++ [ "default" ];
			in
			{
				namespace = [ szy "catalog" "programs" "default" ];

				determine.objects = object:
				builtins.filter
				(
					identifier:
					let
						object = szy'.objects.utils.get { inherit identifier; };
						hasDefault = szy.objects.utils.testInherits
						{
							inherit object;
							template = "default";
						};
					in
						hasDefault
				) object.meta.allTemplates;

				determine.options = object:
				let
					default = szy.lib.attrsets.getFromKeys
					{
						object = object.variable;
						keys = defaultPath object;
					};

					types = builtins.attrNames default.types;

					identifierType = lib.types.nullOr (lib.types.either (lib.types.str) (lib.types.listOf lib.types.str));
				in
				if types == []
				then
				{
					type = identifierType;
					default = null;
				}
				else
				{
					type = 
					let

						module = name:
						{
							options."${name}" = lib.options.mkOption
							{
								type = identifierType;
								default = null;
							};
						};

					in
					lib.types.submoduleWith 
					{ 
						modules =
						builtins.map
						(
							type: 
								module type
						) types;
					};
				};

				determine.config = { object, data }:
				szy.lib.attrsets.createFromKeys
				{
					keys = (defaultPath object) ++ [ "entry" ];
					value = lib.mkIf (data != null)
					(
						if builtins.isAttrs data
						then
						lib.attrsets.filterAttrs
						(
							name: value:
								value != null
						) data
						else data
					);
				};
			};
		}
	];

}
