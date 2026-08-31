{ szy, lib, arguments, ... }:
let

	inherit (szy.objects) utils;

	/*
		Make an object.

		If namespace has a head value of "template" then the object is a template.
	*/
	make' = 
	inputs':
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

			} // data
		) inputs';

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
					template = utils.get { inherit identifier; };
					propagates = utils.getList { list = (template.meta.propagates or []); };
				in
				[ template ] ++ propagates
			) inputs.inherits
		);

		global.identifier = inputs.namespace ++ [ inputs.name ];

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
			variable = getFrom final.variable;
			constant = getFrom final.constant;
			meta = final.meta;
		};

		getFromSchema = path: schema: keys:
		szy.lib.attrsets.deepMergeList
		([
			(
				lib.attrsets.filterAttrs
				(n: v: v != {}) # Remove empty values
				(lib.attrsets.mapAttrs
				(
					name: value:
						getFromSchema (path ++ [ name ]) value keys
				) (builtins.removeAttrs schema [ "inherits" ]))
			)
		]
		++
		(
			builtins.map
			(
				identifier:
				let
					template = utils.get { inherit identifier; };
				in
					(szy.lib.attrsets.getFromKeys { inherit keys; object = template; }) (dataArgument path)
			) (schema.inherits or [])
		));

		finalArgument = dataArgument [];

		getDataPart = part:
		let
			prefix =
			if !inputs.isTemplate
			then [ "meta" "data" ]
			else [ "meta" "template" ];
		in
			szy.lib.attrsets.deepMergeList 
			(
				[
					(getFromSchema [] schema (prefix ++ [ part ])) 
					((lib.trivial.toFunction inputs.private."${part}") finalArgument)
				] ++
				(
					builtins.map
					(
						identifier:
						let
							template = utils.get { inherit identifier; };

							argument = finalArgument //
							{
								getFrom = utils.template.absolute.getFrom global.identifier [ part ];
								setAt = utils.template.absolute.setAt global.identifier [ part ];
							};
						in
						(szy.lib.attrsets.getFromKeys
						{
							keys = prefix ++ [ "absolute" part ];
							object = template;
						}) argument
					) 
					(
						builtins.map
						(
							value: value.identifier
						) allInherits
					)
				)
			);

		# TODO: Try to change this from freestanding options to where variable and constant etc, are options with submodule type! Try to outsource things to the nixos module system.

		output =
		lib.attrsets.mapAttrs
		(
			name: value:
				lib.trivial.toFunction value
		) inputs.output;

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
						type = lib.types.anything; #lib.types.listOf (lib.types.listOf lib.types.str);
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
					}
				);

			} //
			(
				{

					variable = (getDataPart "variable'") //
					{
						enable = lib.options.mkOption
						{
							type = lib.types.bool;
							default = inputs.enable;
						};
					};

					constant = getDataPart "constant'" //
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
	
				}
			)
		);

		config =
		lib.attrsets.setAttrByPath namespace
		{

			variable = getDataPart "variable";
			constant = getDataPart "constant";

		};

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
		];

	};

	make =
	{

		__functor = self: input: make' input;

		template = input':
		let
			input = input' //
			{
				namespace = utils.template.prefix ++ (input'.namespace or []);
			};
		in
			make' input;

	};

in
{

	requiredArguments = [ [ "config" ] ];

	content = make;

}
