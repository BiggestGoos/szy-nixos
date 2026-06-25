{ szy, lib, ... }:
let
	inherit (szy.objects) utils;

	/*
		Composable qualifier:

		Makes objects composable. Define a list of components by path and enable or disable them with a toggle.
	*/
	composable =
	{
		components, /* 
						{ 
							<component-name> = 
							{ 
								path ((builtins.isPath path) == true, then we use path directly, 
								otherwise path must be convertible to string and componentPath set, if that is the case 
								then the string value of path will be appended to componentPath),

								enable (bool)
							}; 
						} 
					*/
		componentPath ? null, # A path to search for components, only used if the given component's path is not of type path.
	}:
	{

		extends = [ "composable" ];

		__functor = self:
		{
			identifier,
			config,
			data,
		}:
		let

			evaluatedComponents = 
			lib.attrsets.mapAttrs 
			(
				name: value:
				{
					enable = lib.mkDefault value.enable;
					path = 
					if (builtins.isPath value.path) 
					then value.path 
					else 
					(
						(
							lib.trivial.throwIfNot (builtins.isPath componentPath) "Must set componentPath to a path value or use only real paths for components." 
							(componentPath)
						) + 
						"/${builtins.toString value.path}"
					);
				}
			) components;

			namespace = utils.definition.namespace identifier;

			final = utils.definition.get { inherit config identifier; };

		in
		szy.lib.attrsets.deepMerge
		data
		{
			imports =
			let

				toggledComponents = lib.attrsets.mapAttrsToList
				(
					name: value:
					let
						enabled = final.data.enabled && final.data.components."${name}".enable;
					in
						szy.lib.imports.toggled.single enabled value.path
				) evaluatedComponents;

			in
			[
				(
					szy.lib.attrsets.createFromKeys { keys = namespace; value =
					{

						data.components = evaluatedComponents;

					}; }
				)
			] ++ toggledComponents;
		};

	};
in
	composable
