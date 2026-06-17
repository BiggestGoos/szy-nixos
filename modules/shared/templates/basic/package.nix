{ szy, lib, config, pkgs, ... }:
szy.objects.declare
{

	inherit config;
	
	name = "package";

	parameters =
	{ final, template }:
	{

		package = lib.options.mkOption
		{
			type = lib.types.package;
			default = 
			let
				name = final.meta.name;
				program = config.programs."${name}" or {};
				service = config.services."${name}" or {};

				package = program.finalPackage or (program.package or (service.finalPackage or (service.package or (pkgs."${name}" or ("No package with name { ${name} }")))));
			in
				package;
		};

	};

}
