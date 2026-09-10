{ szy, config, lib, ... }:
(szy config).objects.make.template
{

	name = "commands";

	/*
		This places the commands option at the root of objects. This is useful as it makes it so that all
		objects that inherit commands has the same structure when it comes to commands. It is thus very
		easy to generate things based on the commands.
	*/
	absolute.variable'.commands =
	lib.options.mkOption
	{

		/*
			Commands is a dictionary of command-names with commands composed of two strings:
			- absolute: A command which should contain (if possible) the absolute path as part of the binary.
			- relative: A command which doesn't contain the path to the binary. 
		*/
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
