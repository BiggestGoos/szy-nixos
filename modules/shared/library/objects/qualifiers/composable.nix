{ szy, lib, config, ... }:
(szy config).objects.make.template
{

	name = "composable";

	variable' =
	{

		components = lib.options.mkOption
		{
			type = 
			let

				module.options =
				{
					path = lib.options.mkOption
					{
						type = lib.types.path;
					};

					enable = lib.options.mkOption
					{ 
						type = lib.types.bool;
					};
				};

			in
			lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });
		};

	};

}
