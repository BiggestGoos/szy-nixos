{ szy, config, lib, ... }:
(szy config).objects.make.template
{

	name = "application";

	inherits =
	[
		"program"
		"desktopEntry"
	];

	schema =
	{
		program = "program";
		entry = "desktopEntry";
	};

	variable =
	{ variable, meta, ... }:
	{

		entry.default.base =
		lib.mkDefault
		{
			package = variable.program.package.input;
			locator = variable.program.package.input.meta.mainProgram or (lib.lists.last meta.identifier); # This will NOT find all desktop entries!
		};

		type = lib.mkForce "gui";

	};

	variable' =
	{ variable, ... }:
	{
		type = lib.options.mkOption
		{
			type = 
			let
				types = 
				[
					"gui"
					"cli"
					"mix"
				];
			in
				lib.types.enum types;
		};
	};

}
