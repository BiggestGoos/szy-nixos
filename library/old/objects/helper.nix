{ identifier, lib, utils, ... }:
let

	getFromKeys = utils.options.getFromKeys;

	global =
	rec {

		namespace = [ identifier "objects" ];

		template.namespace = identifier: global.namespace ++ [ identifier ];

		definition.namespace = 
		{
			name,
			template,
		}@identifier: (global.template.namespace identifier.template) ++ [ "definitions" identifier.name ];

		/*
			Metadata getters:

			All templates and objects have metadata stored in "${szy}".objects.<template-name>.meta and *.<template-name>.definitions.<definition-name>.meta respectively.
			One of the major points of interest in this metadata is the 'namespace' value which holds the keys pointing to where the actual data is.
		*/

		template.getMeta =
		{
			config,
			name ? lib.trivial.throwIf (identifier == null) "No name was supplied." identifier,
			identifier ? null,
		}:
			(getFromKeys { keys = global.template.namespace name; object = config; }).meta or {};
		
		definition.getMeta =
		{
			config,
			name ? identifier.name,
			template ? identifier.template,
			identifier ? {},
		}:
			(getFromKeys { keys = global.definition.namespace { inherit name template; }; object = config; }).meta or {};

		/*
			Data getters:

			First we get metadata containing a namespace value that points to where the real data is.

			All templates are currently (20260613) stored in "${szy}".templates.<template-name> but we still first 
			get their namespace from the metadata and get the data that way to make it more easily changeable.
		*/

		template.get =
		{
			config,
			name ? lib.trivial.throwIf (meta == {} && identifier == null) "No name was supplied." identifier,
			identifier ? null,
			meta ? {},
		}@inputs:
		let
			# If we already have metadata we skip getting it again.
			meta = inputs.meta or (template.getMeta { inherit config name; });
		in
			if (!meta ? namespace) then {} else (getFromKeys { keys = meta.namespace; object = config; });

		definition.get =
		{
			config,
			name ? identifier.name,
			template ? identifier.template,
			identifier ? {},
			meta ? {},
		}@inputs:
		let
			# If we already have metadata we skip getting it again.
			meta = inputs.meta or (definition.getMeta { inherit config name template; });
		in
			if (!meta ? namespace) then {} else (getFromKeys { keys = meta.namespace; object = config; });

		/*
			Misc:
		*/

		template.getAll =
		{
			config,
		}:
			getFromKeys { keys = global.namespace; object = config; };

		template.getFullExtends =
		{
			config,
			name ? lib.trivial.throwIf (identifier == null) "No name was supplied." identifier,
			identifier ? null,
		}@inputs:
		let

			template = global.template.getMeta { inherit config name; };

			getFullExtends = template: 
			let

				extends = template.extends;

				iterate = 
				(
					(
						extends
					) ++ 
					(
						builtins.map 
						(
							name:
							let
								template = global.template.getMeta { inherit (inputs) config; inherit name; };
							in
							(
								if (template.extends != []) 
								then (getFullExtends template) 
								else []
							)
						) 
						extends
					)
				);

			in
				lib.lists.unique (lib.lists.flatten iterate);

		in
			getFullExtends template;

	 };

in
	global
