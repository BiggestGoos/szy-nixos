{ szy, config, lib, ... }:
(szy config).objects.make.template
{

	name = "application";

	inherits =
	[
		"program"
		"desktopEntry"
	];

}
