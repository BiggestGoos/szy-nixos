{ szy, lib, config, ... }:
(szy config).objects.declare
{

	name = "composable";

	parameters =
	{ final, template }:
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
