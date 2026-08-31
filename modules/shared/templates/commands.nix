{ szy, config, lib, ... }:
(szy config).objects.make.template
{

	name = "commands";

	absolute.variable'.commands =
	lib.options.mkOption
	{

		type = 
		let

			module = { config, ... }:
			{
				options =
				let
					option = lib.options.mkOption
					{
						type = lib.types.str;
					};
				in
				{
						
					absolute = option;
					relative = option;
					__toString = lib.options.mkOption
					{
						type = lib.types.functionTo lib.types.str;
						default = self: config.relative;
					};

				};
			};

		in
		lib.types.attrsOf (lib.types.submoduleWith { modules = [ module ]; });		

	};

}
