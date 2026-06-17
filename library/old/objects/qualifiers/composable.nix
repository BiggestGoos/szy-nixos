{ identifier, lib, utils, importLib, helper, ... }@moduleInput:
let
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
					enable = lib.mkDefault value.enable; # TODO: Look into if this really can be lib.mkDefault'ed
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

			namespace = helper.definition.namespace identifier;

			final = helper.definition.get { inherit config identifier; };

		in
		utils.mergeAll 
		[
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
						lib.lists.last 
						(
							moduleInput.importLib.mkToggleable enabled (lib.lists.toList value.path)
						)
					) evaluatedComponents;

				in
				[

					(
						utils.options.createFromKeys { keys = namespace; value =
						{

							data.components = evaluatedComponents;
					
							#meta.extends = [ "composable" ];

						}; }
					)

				] ++ toggledComponents;

			}

		];

	};
in
	composable
