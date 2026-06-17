{ identifier, lib, utils, importLib, helper, internal, qualifiers, ... }@moduleInput:
{

	declare =
	{
		config, # The config object of the caller

		# The name of the template, must be unique
		name,
		# A list of templates, by identifier, to extend
		extends ? [],
		# The default enable value of the template, defaults to true
		enable ? true,

		/*
			Definition data functions, can either be sets or functions to sets. They all take the arguments:
			- final: The final value (gotten from config) of the definition
			- template: The final value (gotten from config) of the definition's template
		*/

		# Data parameters applied to all definitions defining this template
		parameters ? {},
		# Default arguments applied to the parameters of all definitions defining this template
		defaultArguments ? {},

		/*
			Templat data functions, can either be sets or functions to sets. They all take the argument:
			- final: The final value (gotten from config) of the template
		*/

		templateParameters ? {}, # A set of lib.options-style options
		templateArguments ? {},
		
		# Arbitrary options
		options ? {},
		# Arbitrary configuration, is automatically enabled/disabled based on the template's enabled-value, 
		# also recieves the additional argument 'enabled'.
		configuration ? {},

	}@input:
	let
		global =
		{
			identifier = input.name;

			namespace = helper.template.namespace global.identifier;

			final = helper.template.get { inherit config; inherit (global) identifier; };

			resolveSet = internal.resolveSet { inherit (global) final; };
		};
	in
	{

		options = utils.mergeAll 
		[
			(global.resolveSet options)
			(utils.options.createFromKeys { keys = global.namespace; value =
			{
				
				# Metadata about the template
				meta =
				{

					# All templates have an identifier which equals the template's name, this is what makes a template unique
					identifier = utils.options.constant { type = lib.types.str; value = global.identifier; };

					# The name of the template
					name = utils.options.constant { type = lib.types.str; value = input.name; };
	
					# The namespace (under "${szy}".objects) in which the template lies
					namespace = utils.options.constant { type = lib.types.listOf lib.types.str; value = global.namespace; };

					/*
						Definition data:
						Data used directly by definitions defining this template
					*/
					
					parameters = utils.options.constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = parameters; };
					defaultArguments = utils.options.constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = defaultArguments; };

					# Template data:
					template = 
					{
						parameters = utils.options.constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = templateParameters; };
						arguments = utils.options.constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = templateArguments; };
					};

					/*
						A list of templates this template extends, by identifier.
						All definition and template data such as parameters and arguments are inherited and combined from the extended templates.
					*/
					extends = utils.options.constant { type = lib.types.listOf lib.types.str; value = extends; };

					# A list of all definitions directly defining this template, by identifier.
					definitions = 
					let
						identifiers = 
						lib.attrsets.mapAttrsToList
						(
							name: value:
								value.meta.identifier
						)
						global.final.definitions or {};
					in
					utils.options.constant
					{
						type = lib.types.listOf (lib.types.enum identifiers);
						value = identifiers;
					};

					# Data in 'full' is meant to be e.g. _all_ extends, recursively getting this template's extend's extends, etc...
					full = 
					{
						# A list of all templates this extends, directly and indirectly, by identifier
						extends = utils.options.constant 
						{
							type = lib.types.listOf lib.types.str;
							value = helper.template.getFullExtends { inherit (input) config name; };
						};
						# A list of all definitions that definie this template, directly and indirectly, by identifier
						definitions = utils.options.constant 
						{
							type = lib.types.listOf lib.types.attrs;
							value = 
							let
					
								allTemplates = helper.template.getAll { inherit (input) config; };
								allDefinitions = 
								lib.lists.flatten
								(
									lib.attrsets.mapAttrsToList 
									(
										name: value: 
										(
											lib.attrsets.mapAttrsToList 
											(
												name: value: 
													value
											) (value.definitions or {})
										)
									) allTemplates
								);

								definitions = 
								builtins.map 
								(
									definition: 
									{ 
										inherit (definition.meta) name template; 
									}
								) 
								(
									builtins.filter 
									(
										definition: 
											builtins.elem global.final.meta.identifier definition.meta.full.extends
									) 
									allDefinitions
								);

							in
								definitions;
						};
					};

				};

				# Data of the template
				data = lib.options.mkOption 
				{

					type = 
					let

						allTemplates = 
						[
							global.final
						] ++
						(
							builtins.map
							(
								identifier: helper.template.get { inherit (input) config; inherit identifier; }
							) global.final.meta.full.extends
						);

						builtinParameters =
						{

							enable = lib.options.mkOption
							{
								type = lib.types.bool;
								default = enable;
							};

							enabled = 
							let
								hasDefinitions = global.final.meta.full.definitions != {};
								allExtendsEnabled = 
								lib.lists.all 
								(
									identifier: (helper.template.get { inherit (input) config; inherit identifier; }).data.enabled
								) global.final.meta.full.extends;
								combined = hasDefinitions && allExtendsEnabled;
							in
							lib.options.mkOption 
							{
								type = lib.types.bool;
								readOnly = true;
								default = global.final.data.enable && combined;
							};

						};

						parameters =
						builtins.map
						(
							parameters:
							{
								options = global.resolveSet parameters;
							}
						)
						(
							[
								builtinParameters
							] ++
							(
								builtins.map
								(
									template: template.meta.template.parameters
								) allTemplates
							)
						);

						arguments =
						builtins.map
						(
							arguments:
								global.resolveSet arguments
						)
						(
							builtins.map 
							(
								template: template.meta.template.arguments
							) allTemplates
						);
							
					in
						lib.types.submoduleWith { modules = parameters ++ arguments; };

				};

			}; })

		];

		/*
			We make the configuration toggled depending on the enabled value of the template,
			all imports in the configuration are also toggled seperately.
		*/
		imports = 
		let
			anyDefinitionEnabled = 
			lib.lists.any 
			(
				definition: definition.data.enabled
			) 
			(
				builtins.map 
				(
					identifier: helper.definition.get { inherit (input) config; inherit identifier; }
				) global.final.meta.full.definitions
			);
			enabled = global.final.data.enabled && anyDefinitionEnabled;

			arguments =
			{
				inherit (global) final;
				inherit enabled;
			};

			resolved = internal.resolveSet arguments configuration;

			imports = resolved.imports or [];
			result = builtins.removeAttrs resolved [ "imports" ];
		in
		(moduleInput.importLib.mkToggleable enabled imports) ++
		[
			(lib.mkIf (enabled) (result))
		];

	};

}
