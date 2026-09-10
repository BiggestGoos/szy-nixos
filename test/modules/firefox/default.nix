{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	qualifiers =
	[
		{
			name = "composable";
			arguments =
			{
				components =
				{
					alvr.path = ./alvr.nix;
					wivrn.path = ./wivrn.nix;
				};
			};
		}
	];

	name = "firefox";
	namespace = [ "programs" ];

	inherits = [ [ "programs" "browser" ] ];	

	constant.type = "cli";

	variable'.test = lib.options.mkOption
	{
		type = lib.types.listOf lib.types.str;
		default = [];
	};

	output.config =
	{ variable, constant, ... }:
	{
		programs.firefox =
		{
			enable = true;
			package = constant.program.package.final;
		};
	};

}
