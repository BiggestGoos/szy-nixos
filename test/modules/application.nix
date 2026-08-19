{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "application";
	namespace = [ "template" ];

	data' =
	{

		runArgs = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
			default = [];
		};

	};

	constant' =
	{

		type = lib.options.mkOption
		{
			type = lib.types.enum [ "gui" "cli" "both" ];
		};

	};

}
