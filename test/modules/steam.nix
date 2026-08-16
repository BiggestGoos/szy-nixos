{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "test";

	template = true;

	output.config =
	{

		programs.steam.enable = true;

	};

};
