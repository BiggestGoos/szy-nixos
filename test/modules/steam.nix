{ szy, config, lib, ... }:
(szy config).objects.make
{

	name = "steam";
	namespace = [ "applications" ];

	inherits =
	[
		"application"
		"program"
		"program_1"
	];

	schema =
	{
		application =
		{
			inherits = ["application"];
		};
	};

	variable' =
	{ variable, ... }:
	{
		bigPicture = lib.options.mkOption
		{
			type = lib.types.bool;
			default = variable.enable;
		};
	};

	variable =
	{ variable, ... }:
	{

		/*application.runArgs = 
		if variable.bigPicture
		then [ "-tenfootui" ]
		else [ ];*/

		#application.bin = [ "steam" ];

	};

	constant =
	{
		#application.type = "gui";
	};

	output.config =
	{

		programs.steam.enable = true;

	};

	output.options =
	{ variable, ... }:
	{
		test = lib.options.mkOption
		{
			type = lib.types.anything;
			default = variable;
		};
	};

	output.imports =
	{ variable, constant, ... }:
	[
		(
			#{ enabled, ... }:
			#enabled
			{
				programs.firefox.enable = constant.enabled;
			}
		)
	];

}
