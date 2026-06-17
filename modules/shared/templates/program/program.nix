{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "program";

	extends = [ "package" "commands" ];

	parameters =
	{ final, template }:
	{

		program =
		{
			
			bin = lib.options.mkOption
			{
				type = 
				let

					module = { config, ... }:
					{
						options =
						{
						
							finalName = lib.options.mkOption
							{
								type = lib.types.nullOr lib.types.str;
								readOnly = true;
								default = if (config.path == null) then null else (builtins.head (builtins.match ".*/([^/]*)" config.path));
							};

							name = lib.options.mkOption
							{
								type = lib.types.nullOr lib.types.str;
								default = null;
							};

							path = lib.options.mkOption
							{
								type = lib.types.nullOr (lib.types.str // 
								{
									name = "existing path";
									check = (path: builtins.pathExists path);
								});
								default = if (config.name == null) then null else lib.meta.getExe' final.data.package config.name;
							};

							defaultArgs = lib.options.mkOption
							{
								type = lib.types.listOf lib.types.str;
								default = [];
							};

						};
					};

				in
				lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });
			};

			arguments = lib.options.mkOption
			{
				type = 
				let

					module = { config, ... }:
					{
						options =
						{
						
							exe = lib.options.mkOption
							{
								type = 
								let
									exes = builtins.attrNames final.data.program.bin;
								in
									lib.types.enum exes;
								default = "default";
							};

							args = lib.options.mkOption
							{
								type = lib.types.listOf lib.types.str;
								default = if (config.required) then "You need to set the args for this argument!" else [];
							};

							required = lib.options.mkOption
							{
								type = lib.types.bool;
								default = false;
							};

							generateCommand = lib.options.mkOption
							{
								type = lib.types.bool;
								default = true;
							};

						};
					};

				in
				lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });
			};

		};

	};

	defaultArguments =
	{ final, template }:
	{

		program.bin.default.name = lib.mkDefault (final.data.package or { meta = {}; }).meta.mainProgram or null;

		commands =
		let

			exes = final.data.program.bin;
			
			rawArguments = 
			(
				lib.attrsets.mapAttrs 
				(
					name: value: 
					let
						inherit (final.data.program.bin."${value.exe}") defaultArgs;
					in
						value // 
						{ 
							args = defaultArgs ++ value.args; 
						}
				) 
				final.data.program.arguments
			);

			arguments =
			lib.attrsets.filterAttrs
			(
				name: value:
					value.generateCommand
			)
			rawArguments;

			commands = 
			lib.attrsets.mapAttrs
			(
				name: value:
				let

					exe = final.data.program.bin."${value.exe}";

					generateCommand = exe: "${lib.strings.concatStringsSep " " ([ exe ] ++ value.args)}";

				in
				{
					absolute = generateCommand exe.path;
					relative = generateCommand exe.finalName;
				}
			)
			arguments;

		in
			commands;

	};

}
