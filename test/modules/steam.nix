{ szy, config, lib, ... }:
(szy config).objects.define
{

	template = "application";
	name = "steam";

	arguments =
	{
		application.type = "gui";
	};

	configuration =
	{

		programs.steam.enable = true;

	};

}
