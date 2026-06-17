{ config, options, lib, utils, ... }:
let

	optionsName = options;

	values.options = {

		command = lib.mkOption {
			type = lib.types.str;
		};
	
		desktopEntry = lib.mkOption {
			type = lib.types.nullOr lib.types.str;
			default = null;
		};

		package = lib.mkOption {
			type = lib.types.package;
		};

	};

in
{

	mkProgram = { config, name, configuration ? {}, additionalValues ? [], singleInstance ? false, enabledByDefault ? true, guiAndCli ? false }:
	let
		
		resolvedAdditionalValues.options = (builtins.listToAttrs 
			((builtins.map (value: 
				{ 
					name = value.name or value; 
					value = lib.mkOption 
					{ 
						type = value.type or (lib.types.either (lib.types.str) (lib.types.functionTo lib.types.str)); 
					}; 
				}) 
			additionalValues) ++ (lib.lists.optional (guiAndCli) { name = "isGraphical"; value = lib.mkOption { type = lib.types.bool; }; })));

		finalValues = config."${options}".programs."${name}".default.values;
		enabled = if (builtins.hasAttr "instances" config."${options}".programs."${name}") then config."${options}".programs."${name}".enabled else false;

	in
	{

		imports = [ (if (builtins.isFunction configuration) then (configuration { inherit enabled; values = finalValues; optionKeys = [ "programs" name ]; }) else configuration) ];

		options."${options}".programs."${name}" = 
		let

			available = config."${options}".programs."${name}".available;

		in
		{

			available = lib.mkOption {
				type = lib.types.listOf lib.types.str;
				readOnly = true;
				default = if (singleInstance) then [ name ] else (builtins.attrNames (lib.attrsets.filterAttrs (name: value: value.enabled) (config."${options}".programs."${name}".instances or {})));
			};

			enabled = lib.mkOption {
				type = lib.types.bool;
				default = enabledByDefault;
			};

			enabledByDefault = lib.mkOption {
				type = lib.types.bool;
				default = enabledByDefault;
			};

			guiAndCli = lib.mkOption {
				type = lib.types.bool;
				readOnly = true;
				default = guiAndCli;
			};

			default = 
			let
				valuesType = lib.types.nullOr (lib.types.submoduleWith { modules = [ values resolvedAdditionalValues ]; });

				template =
				defaultName:
				{

					name = lib.mkOption {
						type = lib.types.nullOr (lib.types.enum available);
						default = defaultName;
					};

					values = lib.mkOption {
						type = valuesType;
						readOnly = true;
						default = if (defaultName != null) then config."${options}".programs."${name}".instances."${defaultName}".values else null;
					};

					valuesType = lib.mkOption {
						type = lib.types.attrs;
						readOnly = true;
						default = valuesType;
					};

				};
			in
			if (guiAndCli == false) then (template (if (available != []) then (builtins.elemAt available 0) else null)) else
			(let
				findInstance = isGraphical: (lib.lists.findFirst (instanceName: config."${options}".programs."${name}".instances."${instanceName}".values.isGraphical == isGraphical) null available);
			in
			{
				gui = template (findInstance true);
				cli = template (findInstance false);

				valuesType = lib.mkOption {
					type = lib.types.attrs;
					readOnly = true;
					default = valuesType;
				};

			});

		};

	};

	mkInstance = { config, program, name ? program, configuration ? {}, values }:
	let

		command = lib.meta.getExe resolvedValues.package;
		resolvedValues = if (builtins.isFunction values) then values { inherit command; finalCommand = finalValues.command; } else values;

		finalValues = config."${optionsName}".programs."${program}".instances."${name}".values;
		enabled = if (config."${optionsName}".programs."${program}".enabled == false) then false else config."${optionsName}".programs."${program}".instances."${name}".enabled;

		programValues = config."${optionsName}".programs."${program}";

		default = if (programValues.guiAndCli == false) then (programValues.default.name == name) else (if (finalValues.isGraphical) then (programValues.default.gui.name == name) else (programValues.default.cli.name == name));

	in
	{

		imports = [ (if (builtins.isFunction configuration) then (configuration { inherit enabled default; values = finalValues; optionKeys = [ "programs" "${program}" "instances" "${name}" ]; }) else configuration) ];
		
		options."${optionsName}".programs."${program}".instances."${name}" = {

			values = lib.mkOption {
				type = config."${options}".programs."${program}".default.valuesType;
				readOnly = true;
			};

			enabled = lib.mkOption {
				type = lib.types.bool;
				default = config."${optionsName}".programs."${program}".enabledByDefault;
			};

			default = lib.mkOption {
				type = lib.types.bool;
				readOnly = true;
				default = default;
			};

		};

		config."${optionsName}".programs."${program}".instances."${name}".values = lib.mkDefault (if (builtins.elem "command" (builtins.attrNames resolvedValues)) then resolvedValues else (resolvedValues // { inherit command; }));

	};

}
