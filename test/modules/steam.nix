{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "steam";
	namespace = [ "applications" ];

	templates =
	[
		"application"
	];

	schema =
	{
		test = "application";

		inherits =
		[
			"one"
			"two"
			"three"
		];

		test2 =
		{
			test3 = "hello";
			inherits =
			[
				"a"
				"b"
				"c"
			];
			a = { b = "c"; };
		};

	};

	data' =
	{
		bigPicture = lib.options.mkOption
		{
			type = lib.types.bool;
			default = false;
		};
	};

	data =
	{ data, ... }:
	{

		runArgs =
		if data.bigPicture
		then [ "-tenfootui" ]
		else [ ];

	};

	constant =
	{
		type = "gui";
	};

	output.config =
	{

		programs.steam.enable = true;

	};

}
