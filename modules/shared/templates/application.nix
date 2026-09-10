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
	{ variable, constant, meta, ... }:
	{

		/*
			Will try to find a desktop entry for the application in the input package.
			This will not always find one as it only tests either the package's 'mainProgram' name
			or the object's name.
		*/
		entry.default.base =
		let
			package = variable.program.package.input;
		in
		lib.mkDefault
		{
			inherit package;
			locator = package.meta.mainProgram or (lib.lists.last meta.identifier); # This will NOT find all desktop entries!
		};

		/*
			If the application is a mix of gui and cli then it gets two more default actions:
			- open: Opens the application graphically
			- run: Runs the application in a terminal
		*/
		program.actions =
		let
			inherit (variable.program.actions) default;
			inherit (constant) type;

			fromDefault =
			{
				bin = lib.mkDefault default.bin;
				arguments = lib.mkDefault default.arguments;
			};
		in
		lib.mkIf (type == "mix")
		{
			open = fromDefault;
			run = fromDefault;
		};

	};

	constant' =
	{
		/*
			The type of application:
			- gui: A graphical application
			- cli: A command-line application
			- mix: A mix of gui and cli
		*/
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
			readOnly = true;
		};
	};

	/*
		If a template inherits application and 'default' then we automatically set up
		some different default types.
	*/
	template.absolute.variable =
	{ setAt, meta, constant, ... }:
	if (szy config).objects.utils.testInherits
	{
		inherit (meta) identifier;
		template = "default";
	}
	then
	(
		setAt "default"
		{
			default.types =
			let
				testObject = object: types: 
				builtins.elem 
				(
					(szy config).objects.utils.template.absolute.getFrom object.meta.identifier "constant" "application"
				).type types;

				inherit (constant) default;
				gui = (default.gui.meta or { identifier = null; }).identifier;
				cli = (default.cli.meta or { identifier = null; }).identifier;
			in
			{
				gui = object: testObject object [ "mix" "gui" ]; # Has graphical part
				cli = object: testObject object [ "mix" "cli" ]; # Has command-line part
				any = object: object.meta.identifier == gui || object.meta.identifier == cli; # Anything that is default in some category, doesn't matter if it's graphical or command-line
			};
		}
	)
	else {};

}
