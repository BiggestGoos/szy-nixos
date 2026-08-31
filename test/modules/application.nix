{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "application";
	namespace = [ "template" ];

	#propagates = [ "program" ];

	variable' =
	{

		runArgs = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
			default = [];
		};

		program =
		{
			test = lib.options.mkOption
			{
				type = lib.types.str;
				default = "hello";
			};
		};

	};

	variable =
	{ variable, ... }:
	{

		runArgs = lib.mkDefault variable.bin;

	};

	constant' =
	{

		type = lib.options.mkOption
		{
			type = lib.types.enum [ "gui" "cli" "both" ];
		};

	};

}
