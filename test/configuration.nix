{ lib, szy, ... }:
{

	nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

	"${szy}".objects =
	{

		programs =
		{
			steam =
			{
				variable.enable = true;
			};
			firefox.variable.enable = true;
			chrome.variable.enable = true;
		};

		template.programs =
		{
			browser.variable.default =
			{
				entry.any = "chrome";
			};
		};

	};

}
