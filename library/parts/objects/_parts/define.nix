{ lib, szy, arguments, ... }:
let

	inherit (arguments) config;
	inherit (szy) objects;
	inherit (objects) utils;

	/*
		Resolve a definition, this can then be modified with qualifiers.
	*/
	resolveDefinition = 	
	{	
		# The template to define
		template,
		# The name of the definition, must be unique for a definition of a given template
		name,
		# The default enable value of the definition, defaults to false
		enable ? false,

		# Additional templates to implement
		extends ? [],
		
		/*
			Functions, can either be sets or functions to sets. They all take the arguments:
			- final: The final value (gotten from config) of the definition
			- template: The final value (gotten from config) of the definition's template
		*/

		# Arguments for the definition parameters
		arguments ? {},
		# Additional parameters for the definition
		additionalParameters ? {},

		# Arbitrary options
		options ? {},
		# Arbitrary configuration, is automatically enabled/disabled based on the definition's enabled-value, 
		# also recieves the additional argument 'enabled'.
		configuration ? {},

		metaArguments ? {}, # Fulfill additional meta parameters
		...
	}@input:
	let
		global =
		{
			identifier = { inherit (input) name template; };

			namespace = utils.definition.namespace global.identifier;

			template = utils.template.get { inherit config; name = input.template; };
			templates = 
			builtins.map
			(
				name: 
					utils.template.get { inherit config name; }
			) global.final.meta.full.extends;

			final = utils.definition.get { inherit config; inherit (global) identifier; };

			resolveSet = (lib.trivial.flip szy.lib.functions.resolveValue) { inherit (global) final template; };
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

				# Metadata about the definition
				meta =
				let
					inherit (szy.lib.options) constant;
				in
				{

					# All definitions have an identifier composed of name and template(-name), this is what makes a definition unique
					identifier =
					{
						name = constant { type = lib.types.str; value = input.name; };
						template = constant { type = lib.types.str; value = input.template; };
					};

					# The name of the definition
					name = constant { type = lib.types.str; value = input.name; };
					# The main template the definition defines
					template = constant { type = lib.types.str; value = input.template; };

					# The namespace (under "${szy}".objects) in which the definition lies
					namespace = constant { type = lib.types.listOf lib.types.str; value = global.namespace; };

					# Additional meta data
					metaData =
					let
						allMetaParameters =
						builtins.map
						(
							template: 
							{
								options = global.resolveSet template.meta.metaParameters.object;
							}
						) global.templates;

						allDefaultArguments =
						builtins.map
						(
							template:
								global.resolveSet template.meta.defaultMetaArguments.object
						) global.templates;

						metaArguments = global.resolveSet (input.metaArguments or {});

						metaArgument = szy.lib.attrsets.deepMergeList (allDefaultArguments ++ [ metaArguments ]);

					in
					constant
					{
						type = lib.types.submoduleWith { modules = allMetaParameters; };
						value = metaArgument;
					};

					# A list of templates this definition extends, by identifier
					extends = constant { type = lib.types.listOf lib.types.anything; value = extends; }; # TODO: Make this be a list of enum of all possible templates.

					# A list of all templates, by identifier, that this definition ultimately extends, including the main template
					full.extends = constant
					{
						type = lib.types.listOf lib.types.str; # TODO: Make this be a list of enum of all possible templates.
						value =
						let
							# All templates that this definition _directly_ extends
							templates = 
							[ 
								global.template.meta
							] ++ 
							(
								builtins.map
								(
									identifier: 
										utils.template.getMeta { inherit config identifier; }
								) 
								global.final.meta.extends
							);
							allExtends = 
							lib.lists.unique 
							(
								[ global.template.meta.identifier ] ++
								global.final.meta.extends ++ 
								(
									builtins.concatLists 
									(
										builtins.map 
										(
											template: 
												template.full.extends
										) 
										templates
									)
								)
							);
						in
							allExtends;
					};

				};

				# Data of the definition
				data = lib.options.mkOption
				{

					type = 
					let

						# All template's data
						templates = 
						builtins.map 
						(
							identifier: 
							utils.template.get 
							{ 
								inherit config identifier; 
							}
						) 
						global.final.meta.full.extends;

						templateParameters = builtins.map (template: template.meta.parameters) templates;
						definitionParameters = input.additionalParameters or {};

						builtinParameters =
						{

							enable = lib.options.mkOption
							{
								type = lib.types.bool;
								default = enable;
							};

							enabled = lib.options.mkOption 
							{
								type = lib.types.bool;
								# readOnly = true; Probably should be readOnly, TODO: Try when things work
								default = 
								let
									allTemplatesEnabled = lib.lists.all (template: template.data.enabled) global.templates;
								in
									global.final.data.enable && allTemplatesEnabled;
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
						([ builtinParameters definitionParameters ] ++ templateParameters);

						templateArguments = builtins.map (template: template.meta.defaultArguments) global.templates;
						definitionArguments = input.arguments or {};

						arguments = 
						builtins.map
						(
							arguments:
								global.resolveSet arguments
						)
						([ definitionArguments ] ++ templateArguments);

					in
						lib.types.submoduleWith { modules = parameters ++ arguments; };

				};

			}; 
		});

		/*
			We make the configuration toggled depending on the enabled value of the definition,
			all imports in the configuration are also toggled seperately.
		*/
		imports = 
		let
			enabled = global.final.data.enabled;

			arguments =
			{
				inherit enabled;
				inherit (global) final template;
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

	/*
		Define an object using the given template. Takes arguments that fulfill the template as well as other modifying the "template" used.

		See 'resolveDefinition' for more parameters and implementation.
	*/
	define =
	{ 
		template,
		name,
		/*
			A set or list of qualifiers to be applied to the definition,
			attribute names map to qualifier functions and the values are given as arguments to those functions

			The attribute _meta.order can be used to specify in which order the qualifiers will be applied, otherwise the order is undefined.
			If list then the order is in the order of the list.
		*/
		qualifiers ? {}, # { <qualifier> = { <arguments> }; }, alt [ { name = <qualifiers-name>; arguments = { <arguments> }; } ... ]
		...
	}@input:
	let

		final = szy.objects.utils.definition.get { identifier = { inherit name template; }; };
		template = szy.objects.utils.template.get { identifier = template; };

		# We call qualifiers with the optional parameter final
		qualifiers = szy.lib.functions.resolveValue (input.qualifiers or {}) { inherit final template; };

		order' = 
		if (qualifiers ? _meta) && (builtins.isAttrs qualifiers._meta) && (qualifiers._meta ? order)
		then qualifiers._meta.order
		else builtins.attrNames qualifiers;

		allQualifiers = szy.objects.qualifiers.definition or {};

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

		output = resolveDefinition resolvedInput;

		/*
			Apply the qualifier functions to the resolved definition output in the defined (or not) order
		*/
		resolve = 
		lib.lists.foldl 
		(
			data: qualifier: 
			qualifier 
			{
				inherit config data;
				identifier = { inherit name template; };
			}
		) output;

		result = resolve orderedQualifiers;
	in
		result;

in
{

	requiredArguments = [ [ "config" ] ];

	content = define;

}
