{ szy, lib, arguments, ... }:
let

	inherit (arguments) config;
	inherit (szy.objects) utils;

	/*
		Make an object.

		If namespace has a head value of "template" then the object is a template.
	*/
	makeBase = 
	inputs:
	let

		propagates =
		builtins.map
		(
			identifier:
				utils.template.resolveIdentifier identifier
		) inputs.propagates;

		inherits = 
		builtins.concatLists
		(
			builtins.map
			(
				identifier':
				let
					identifier = utils.template.resolveIdentifier identifier';
					templateTry = builtins.tryEval(utils.get { inherit identifier; });
					template =
					if templateTry.success
					then templateTry.value
					else builtins.throw "Failed to get inherited template ${builtins.toJSON identifier} for object ${builtins.toJSON global.identifier}";
					propagates = utils.getList { list = (template.meta.propagates or []); };
				in
				[ template ] ++ propagates
			) inputs.inherits
		);

		global.identifier = inputs.identifier;

		schema =
		let
		
			usedInherits = 
			let
				currentUsed = schemaLevel:
				builtins.concatLists
				(
					lib.attrsets.mapAttrsToList
					(
						name: value:
						if name != "inherits"
						then
						(
							if builtins.isAttrs value
							then currentUsed value
							else [ (utils.template.resolveIdentifier value) ]
						)
						else
						(
							builtins.map
							(
								identifier:
									utils.template.resolveIdentifier identifier
							) value
						)
					) schemaLevel
				);
			in
				currentUsed inputs.schema;

			notUsed = lib.lists.subtractLists usedInherits 
			(
				builtins.map
				(
					value:
						value.meta.identifier
				) inherits
			);

			resolveInherits = schema:
			if builtins.isAttrs schema && schema ? "inherits"
			then
			(
				szy.lib.attrsets.deepMergeList
				(
					builtins.map
					(
						identifier':
						let
							identifier = utils.template.resolveIdentifier identifier';
							template = utils.get { inherit identifier; };
						in
							template.meta.schema
					) schema.inherits
				)
			)
			else schema;

			resolveSchema = schema:
			szy.lib.attrsets.deepMerge
			(resolveInherits schema)
			(
				lib.attrsets.mapAttrs
				(
					name: value:
					let
						identifier = (builtins.tryEval (utils.template.resolveIdentifier value)).value;
						template = utils.get { inherit identifier; };
					in
					if identifier != false
					then template.meta.schema
					else resolveSchema value
				) (builtins.removeAttrs schema [ "inherits" ])
			);

			inputSchema =
			szy.lib.attrsets.deepMerge
			inputs.schema
			{
				inherits = notUsed;
			};

			resolvedSchema = resolveSchema inputSchema;

		in
		(
			szy.lib.attrsets.deepMerge
			resolvedSchema
			{
				inherits = [ global.identifier ];
			}
		);

		allInherits =
		let

			allInheritsIn = path: schemaLevel:
			builtins.concatLists
			(
				lib.attrsets.mapAttrsToList
				(
					name: value:
					if name == "inherits"
					then 
					builtins.map
					(
						identifier:
						{
							inherit identifier path;
						}
					) value
					else allInheritsIn (path ++ [ name ]) value
				) schemaLevel
			);

		in
			allInheritsIn [] schema;

		namespace = szy.objects.utils.namespace ++ global.identifier;

		final = utils.get { inherit (global) identifier; };

		dataArgument = path:
		let
			getFrom = object:
			szy.lib.attrsets.getFromKeys
			{
				keys = path;
				inherit object;
			};
		in
		{
			variable = /*builtins.trace "${builtins.toJSON global.identifier}, ::: ${builtins.toJSON path}"*/ (getFrom final.variable);
			constant = getFrom final.constant;
			absolute =
			{
				inherit (final) variable constant;
			};
			meta = final.meta;
		};

		finalArgument = dataArgument [];

		getDataPart = part:
		let
			prefix =
			if !inputs.isTemplate
			then [ "meta" "data" ]
			else [ "meta" "template" ];
		in
		[
			((lib.trivial.toFunction inputs.private."${part}") finalArgument)
		] ++
		(builtins.concatLists
		(
			builtins.map
			(
				{ identifier, path }:
				let
					template = utils.get { inherit identifier; };
					relativeData =
					let
						data =
						(
							szy.lib.attrsets.getFromKeys
							{
								keys = prefix ++ [ part ];
								object = template;
							}
						) (dataArgument path);
					in
					if data != {}
					then
					szy.lib.attrsets.createFromKeys
					{
						keys = path;
						value = data;
					}
					else {};

					absoluteData =
					let
						argument = finalArgument //
						{
							getFrom = utils.template.absolute.getFrom global.identifier;
							setAt = utils.template.absolute.setAt global.identifier;
						};
					in
					(
						szy.lib.attrsets.getFromKeys
						{
							keys = prefix ++ [ "absolute" part ];
							object = template;
						}
					) argument;
				in
				[
					relativeData
					absoluteData
				]
			) allInherits
		));
	
		output =
		lib.attrsets.mapAttrs
		(
			name: value:
				lib.trivial.toFunction value
		) ((lib.trivial.toFunction inputs.output) finalArgument);

	in
	szy.lib.attrsets.deepMerge
	{

		options = 
		let
			inherit (szy.lib.options) constant;
		in
		lib.attrsets.setAttrByPath namespace
		(
			{

				meta =
				let

					dataOptions = inputs:
					{
						variable' = constant
						{
							type = szy.lib.options.types.callable;
							value = lib.trivial.toFunction inputs.variable';
						};

						variable = constant
						{
							type = szy.lib.options.types.callable;
							value = lib.trivial.toFunction inputs.variable;
						};

						constant' = constant
						{
							type = szy.lib.options.types.callable;
							value = lib.trivial.toFunction inputs.constant';
						};
						
						constant = constant
						{
							type = szy.lib.options.types.callable;
							value = lib.trivial.toFunction inputs.constant;
						};

						absolute = 
						{

							variable' = constant
							{
								type = szy.lib.options.types.callable;
								value = lib.trivial.toFunction inputs.absolute.variable';
							};

							variable = constant
							{
								type = szy.lib.options.types.callable;
								value = lib.trivial.toFunction inputs.absolute.variable;
							};

							constant' = constant
							{
								type = szy.lib.options.types.callable;
								value = lib.trivial.toFunction inputs.absolute.constant';
							};
							
							constant = constant
							{
								type = szy.lib.options.types.callable;
								value = lib.trivial.toFunction inputs.absolute.constant;
							};

						};
					};

				in
				{

					identifier = constant
					{
						type = lib.types.listOf lib.types.str;
						value = global.identifier;
					};

					prettyName = constant
					{
						type = lib.types.str;
						value = lib.strings.concatStringsSep "." global.identifier;
					};

					inherits = constant
					{
						type = lib.types.listOf (lib.types.listOf lib.types.str); # TODO: Add validation that these are real objects and that you are not inheriting something multiple times, directly or indirectly.
						value = 
						builtins.map
						(
							template:
								template.meta.identifier
						) inherits;
					};

					allInherits = constant
					{
						type = lib.types.anything;
						value = allInherits;
					};

					schema = constant
					{
						type = lib.types.attrs;
						value = schema;
					};

					data = dataOptions inputs;

				}
				//
				(
					if !inputs.isTemplate
					then {}
					else
					{
						template = dataOptions inputs.template;
						
						propagates = constant
						{
							type = lib.types.listOf (lib.types.listOf lib.types.str);
							value = propagates;
						};

						allObjects = constant
						{
							type = lib.types.anything;
							value = utils.template.getAllObjects { inherit (global) identifier; };
						};

						allTemplates = constant
						{
							type = lib.types.anything;
							value = utils.template.getAllTemplates { inherit (global) identifier; };
						};
					}
				);

			} //
			(
				let
					modules = type:
					let
						addPrefix = prefix: list:
						builtins.map
						(
							value:
							{
								"${prefix}" = value;
							}
						) list;
					in
					(addPrefix "options" (getDataPart "${type}'")) ++
					(addPrefix "config" (getDataPart type));
				in
				{

					variable = lib.options.mkOption
					{
						type = lib.types.submoduleWith
						{
							modules =
							let
								extraModule.options =
								{
									enable = lib.options.mkOption
									{
										type = lib.types.bool;
										default = inputs.enable;
									};
								};
							in 
							(modules "variable")
							++
							[
								extraModule
							];
						};
					};

					constant = lib.options.mkOption
					{
						type = lib.types.submoduleWith
						{
							modules = 
							let
								extraModule.options =
								{
									enabled = constant
									{
										type = lib.types.bool;
										value = final.variable.enable &&
										(
											builtins.all
											(x: x == true)
											(
												builtins.map
												(
													template:
														template.constant.enabled
												) inherits
											)
										);
									};
								};
							in
							(modules "constant")
							++
							[
								extraModule
							];
						};
					};
	
				}
			)
		);

	}
	{

		options = output.options finalArgument;
		imports = 
		(
			szy.lib.imports.toggled.listWithArgs final.constant.enabled finalArgument (output.imports finalArgument)
		)
		++
		[
			(
				lib.mkIf final.constant.enabled (output.config finalArgument)
			)
			(
				let
					type = 
					if inputs.isTemplate
					then "templates"
					else "objects";
				in
				szy.lib.attrsets.createFromKeys
				{
					keys = utils.namespace;
					value.meta."${type}" = [ global.identifier ];
				}
			)
		];

	};

	resolveInputs = inputs':
	let

		data' =
		{
			variable' = [ {} ];
			variable = [ {} ];

			constant' = [ {} ];
			constant = [ {} ];
		};

		data = data' //
		{
			absolute = data';
		};

		inputs = szy.lib.functions.followSchema
		(
			final:
			let
				inherit (final) namespace;
				isTemplate =
				if !(builtins.isList namespace && namespace != [])
				then false
				else (lib.lists.take 1 namespace) == utils.template.prefix;
			in
			{
				identifier = [ (final.namespace ++ [ final.name ]) ];

				name = {};
				namespace = [ [] ];
				
				isTemplate = [ isTemplate ];

				/*
					A list of either string or list of string. Just a string will be
					interpreted as a list of one string.
				*/
				inherits = [ [] ];
				propagates = [ [] ];

				/*
					This schema decides how this object includes templates.
				*/
				schema = [ {} ];

				enable = [ isTemplate ];

				private = data';
				template = data;

				output =
				{
					config = [ {} ];
					options = [ {} ];
					imports = [ [] ];
				};

				qualifiers = [ [] ];
			} // data
		) inputs';

	in
		inputs;

	makeQuantifiers = inputs': 
	let
		qualifiers' = inputs'.qualifiers;
		qualifiers =
		builtins.map
		(
			{ name, arguments }:
			let
				qualifier = szy.objects.qualifiers."${name}";
			in
				qualifier arguments
		) qualifiers';

		qualifierInherits =
		lib.lists.unique
		(
			builtins.concatLists
			(
				builtins.map
				(
					qualifier:
					if builtins.isAttrs qualifier
					then qualifier.inherits or []
					else []
				) qualifiers
			)
		);

		inputs = inputs' //
		{
			inherits = inputs'.inherits ++ qualifierInherits;
		};

		base = makeBase inputs;

		final =
		lib.lists.foldl
		(
			data: qualifier:
			qualifier
			{
				inherit data config;
				inherit (inputs) identifier;
			}
		) base qualifiers;
	in
		final;

	makeFinal = inputs': 
	let
		inputs = resolveInputs inputs';
	in
		makeQuantifiers inputs;

	make =
	{

		__functor = self: input: makeFinal input;

		template = input':
		let
			input = input' //
			(
				if input' ? identifier
				then
				{
					identifier = utils.template.prefix ++ input'.identifier;
				}
				else
				{
					namespace = utils.template.prefix ++ (input'.namespace or []);
				}
			);
		in
			makeFinal input;

	};

in
{

	requiredArguments = [ [ "config" ] ];

	content = make;

}
