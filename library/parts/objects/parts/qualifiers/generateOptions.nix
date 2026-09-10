{ szy, lib, ... }:
let
	inherit (szy.objects) utils;

	default.determine =
	{

		options = object:
		let
			module =
			{
				freeformType = szy.lib.options.types.anything;
										
				options =
				{
					final = szy.lib.options.constant
					{
						type = lib.types.attrs;
						value = object;
					};
				};
			};
		in
		{
			type = lib.types.submoduleWith { modules = [ module ]; };
		};

		config = { object, data }: builtins.removeAttrs data [ "final" ];

	};

	generateOptions = inputs':
	let

		inputs = szy.lib.functions.followSchema
		{
			/*
				List of strings building up namespace where the options should end up.
			*/
			namespace = {};
			determine =
			with (default.determine);
			{
				/*
					List of identifiers to objects we should generate options for 
					(or function returning, taking the object the qualifier is applied to as argument)
				*/
				objects = {};
				/*
					List of strings (or single string interpreted as singleton list) building up namespace where objects end up, relative to upper-namespace
					(or function returning, taking individual objects and returning a namespace where they should end up)

					If the value '[]' is set, as by default, 
					then objects will actually use the namespace (lib.lists.last object.meta.identifier).
				*/
				namespace = [ [] ];
				/*
					A function taking individual objects and returning a value which will create an options with lib.options.mkOption
					at that objects namespace.
				*/
				options = [ options ];
				/*
					A function taking individual objects as well as data set in it's options and returning an attrset in a correct format
					such that it can be applied to the object's variable data.

					If value 'null' is returned (alternatively simply set to 'null') then no data is applied.
				*/
				config = [ config ];
			};
		} inputs';

		baseNamespace =
		builtins.map
		(
			value: "${value}"
		) inputs.namespace;

	in
	{

		inherits = [ "generateOptions" ];

		__functor = self:
		{
			identifier,
			config,
			data,
		}:
		let

			final = utils.get { inherit config identifier; };

			finalNamespace = namespace: object:
			let
				finalNamespace =
				if namespace == []
				then lib.lists.last object.meta.identifier
				else namespace;
			in
				lib.lists.toList finalNamespace;

			objects =
			let
				objects' =
				let
					identifiers = (lib.trivial.toFunction inputs.determine.objects) final;
				in
					utils.getList { inherit config; list = identifiers; };
			in
			builtins.map
			(
				object:
				let
					namespace = (lib.trivial.toFunction inputs.determine.namespace) object;
					namespace' = baseNamespace ++ (finalNamespace namespace object);
					data = lib.attrsets.getAttrFromPath namespace' config;
				in
				{
					inherit object namespace;
					config = (lib.trivial.toFunction inputs.determine.config) { inherit object data; };
				}
			) objects';

			output.options =
			lib.attrsets.setAttrByPath baseNamespace
			(
				szy.lib.attrsets.deepMergeList
				(
					builtins.map
					(
						{ namespace, object, ... }:
						let
							options = inputs.determine.options object;
						in
						lib.attrsets.setAttrByPath (finalNamespace namespace object) (lib.options.mkOption options)
					) objects
				)
			);

			objectsConfig =
			builtins.filter
			(
				{ config, ... }: config != null
			) objects;

			output.config =
			if inputs.determine.config == null
			then {}
			else
			let
				namespace = utils.namespace ++ [ "template" "generateOptions" "variable" "data" ];
			in
			lib.attrsets.setAttrByPath namespace
			(
				builtins.map
				(
					{ object, config, ... }:
					{
						data = config;
						inherit (object.meta) identifier;
					}
				) objectsConfig
			);

		in
		szy.lib.attrsets.deepMerge
		data
		{

			imports =
			[
				output
			];

		};

	};
in
	generateOptions
