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
								path: Either a path or a string holding a path relative to componentPath. 

								enable: bool, defaults to false
							}; 
						} 
					*/
		componentPath ? null, # A path to search for components, only used if the given component's path is not of type path.
	}:
	{

		inherits = [ "composable" ];

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
					enable = lib.mkDefault (value.enable or false);
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

			namespace = utils.namespace ++ identifier;

			final = utils.get { inherit config identifier; };
		in
		szy.lib.attrsets.deepMerge
		data
		{
			imports =
			let

				toggledComponents = 
				lib.attrsets.mapAttrsToList
				(
					name: value:
					let
						components = (utils.template.absolute.getFrom identifier "variable" "composable").components;
						enabled = final.constant.enabled && components."${name}".enable;
					in
						szy.lib.imports.toggled.single enabled value.path
				) evaluatedComponents;

			in
			[
				(
					szy.lib.attrsets.createFromKeys 
					{ 
						keys = namespace ++ [ "variable" ]; 
						value =
						utils.template.absolute.setAt identifier "composable"
						{
							components = evaluatedComponents;
						}; 
					}
				)
			] ++ toggledComponents;
		};

	};
in
	composable
