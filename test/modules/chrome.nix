{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "chrome";
	namespace = [ "programs" ];

	inherits = [ [ "programs" "browser" ] ];	

	constant.type = "gui";

	output.config =
	{ variable, constant, ... }:
	{
		programs.chromium =
		{
			enable = true;
			#package = constant.program.package.final;
		};
	};

}
