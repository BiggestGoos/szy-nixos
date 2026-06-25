{ szy, lib, arguments, ... }:
let

	inherit (arguments) config;
	inherit (szy.objects) utils;

	resolveDeclaration =
	{	
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
		
		metaParameters ? {}, # Add additional meta parameters
		metaArguments ? {}, # Fulfill the additional meta parameters
		defaultMetaArguments ? {}, # Passed along to templates and objects
		...
	}@input:
	let
		global =
		{
			identifier = input.name;

			namespace = utils.template.namespace global.identifier;

			final = utils.template.get { inherit (global) identifier; };

			resolveSet = (lib.trivial.flip szy.lib.functions.resolveValue) { inherit (global) final; };
		};
	in
	{

		options = szy.lib.attrsets.deepMerge
		(
			global.resolveSet options
		)
		(
			szy.lib.attrsets.createFromKeys { keys = global.namespace; value =
			{
				
				# Metadata about the template
				meta =
				let
					inherit (szy.lib.options) constant;
				in
				{

					# All templates have an identifier which equals the template's name, this is what makes a template unique
					identifier = constant { type = lib.types.str; value = global.identifier; };

					# The name of the template
					name = constant { type = lib.types.str; value = input.name; };
	
					# The namespace (under "${szy}".objects) in which the template lies
					namespace = constant { type = lib.types.listOf lib.types.str; value = global.namespace; };

					/*
						Definition data:
						Data used directly by definitions defining this template
					*/
					
					parameters = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = parameters; };
					defaultArguments = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = defaultArguments; };

					# Template data:
					template = 
					{
						parameters = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = templateParameters; };
						arguments = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = templateArguments; };
					};

					# Meta parameters:
					metaParameters =
					{
						object = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = metaParameters.object or {}; };
						template = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = metaParameters.template or {}; };
					};

					defaultMetaArguments =
					{
						object = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = defaultMetaArguments.object or {}; };
						template = constant { type = lib.types.either (lib.types.attrs) (lib.types.functionTo lib.types.attrs); value = defaultMetaArguments.template or {}; };						
					};
				
					# Additional meta data
					metaData =
					let
						allExtends =
						builtins.map
						(
							identifier:
								utils.template.get { inherit identifier; }
						) global.final.meta.full.extends;

						allParameters =
						builtins.map
						(
							template: 
							{ 
								options = global.resolveSet template.meta.metaParameters.template;
							}
						) ([ global.final ] ++ allExtends);

						allDefaultArguments =
						builtins.map
						(
							template:
								global.resolveSet template.meta.defaultMetaArguments.template
						) ([ global.final ] ++ allExtends);

						metaArguments = global.resolveSet (input.metaArguments or {});

						metaArgument = szy.lib.attrsets.deepMergeList (allDefaultArguments ++ [ metaArguments ]);
					in
					constant
					{
						type = lib.types.submoduleWith { modules = allParameters; };
						value = metaArgument;
					};

					/*
						A list of templates this template extends, by identifier.
						All definition and template data such as parameters and arguments are inherited and combined from the extended templates.
					*/
					extends = constant { type = lib.types.listOf lib.types.str; value = extends; };

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
					constant
					{
						type = lib.types.listOf (lib.types.enum identifiers);
						value = identifiers;
					};

					# Data in 'full' is meant to be e.g. _all_ extends, recursively getting this template's extend's extends, etc...
					full = 
					{
						# A list of all templates this extends, directly and indirectly, by identifier
						extends = constant 
						{
							type = lib.types.listOf lib.types.str;
							value = utils.template.getFullExtends { inherit name; };
						};
						# A list of all definitions that definie this template, directly and indirectly, by identifier
						definitions = constant 
						{
							type = lib.types.listOf lib.types.attrs;
							value = 
							let
					
								allTemplates = utils.template.getAll {};
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
								identifier: utils.template.get { inherit identifier; }
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
									identifier: (utils.template.get { inherit identifier; }).data.enabled
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

			}; 
		});

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
					identifier: utils.definition.get { inherit identifier; }
				) global.final.meta.full.definitions
			);
			enabled = global.final.data.enabled && anyDefinitionEnabled;

			arguments =
			{
				inherit (global) final;
				inherit enabled;
			};

			resolved = szy.lib.functions.resolveValue configuration arguments;

			imports = resolved.imports or [];
			result = builtins.removeAttrs resolved [ "imports" ];
		in
		(szy.lib.imports.toggled.listWithArgs enabled arguments imports) ++
		[
			(lib.mkIf (enabled) (result))
		];

	};

	declare =
	{ 
		name,
		/*
			A set or list of qualifiers to be applied to the declaration,
			attribute names map to qualifier functions and the values are given as arguments to those functions

			The attribute _meta.order can be used to specify in which order the qualifiers will be applied, otherwise the order is undefined.
			If list then the order is in the order of the list.
		*/
		qualifiers ? {}, # { <qualifier> = { <arguments> }; }, alt [ { name = <qualifiers-name>; arguments = { <arguments> }; } ... ]
		...
	}@input:
	let

		final = szy.objects.utils.template.get { identifier = name; };

		# We call qualifiers with the optional parameter final
		qualifiers = szy.lib.functions.resolveValue (input.qualifiers or {}) { inherit final; };

		order' = 
		if (qualifiers ? _meta) && (builtins.isAttrs qualifiers._meta) && (qualifiers._meta ? order)
		then qualifiers._meta.order
		else builtins.attrNames qualifiers;

		allQualifiers = szy.objects.qualifiers.template or {};

		order = (lib.trivial.checkListOfEnum "Qualifiers" (builtins.attrNames allQualifiers) order') order';

		orderedQualifiers = 
		if (builtins.isAttrs qualifiers)
		then
		(
			builtins.map
			(
				name: 
					allQualifiers."${name}" qualifiers."${name}"
			) order
		)
		else
		(
			builtins.map
			(
				{ name, arguments }:
					allQualifiers."${name}" arguments
			) qualifiers
		);

		qualifierExtends = 
		builtins.concatLists
		(
			builtins.map
			(
				qualifier:
					qualifier.extends or []
			) orderedQualifiers
		);

		resolvedInput = 
		szy.lib.attrsets.deepMerge
		input
		{
			extends = qualifierExtends;
		};

		output = resolveDeclaration resolvedInput;

		/*
			Apply the qualifier functions to the resolved declaration output in the defined (or not) order
		*/
		resolve = 
		lib.lists.foldl 
		(
			data: qualifier: 
			qualifier 
			{
				inherit config data;
				identifier = name;
			}
		) output;

		result = resolve orderedQualifiers;
	in
		result;

in
{

	requiredArguments = [ [ "config" ] ];

	content = declare;

}
