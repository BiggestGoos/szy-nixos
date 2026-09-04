{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	name = "zsh";
	namespace = [ "programs" ];

	inherits = [ [ "programs" "shell" ] ];	

	constant.type = "cli";

	output.config =
	{ variable, constant, ... }:
	{
		programs.zsh =
		{
			enable = true;
			package = constant.package.final;
		};
	};

}
