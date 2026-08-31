{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "program";
	namespace = [ "template" ];

	variable' =
	{

		bin = lib.options.mkOption
		{
			type = lib.types.listOf lib.types.str;
			default = [];
		};

	};

	template.variable' =
	{

		default = lib.options.mkOption
		{
			type = lib.types.str;
		};

	};

	template.variable =
	{
		default = lib.mkDefault "hello";
	};

	private.variable' =
	{ variable, ... }:
	{
		privateTest = lib.options.mkOption
		{
			type = lib.types.str;
			default = variable.default;
		};
	};

}
