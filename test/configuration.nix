{ lib, szy, pkgs, ... }:
{

	nixpkgs.config.allowUnfree = true;

	imports = szy.lib.imports.recursive ./modules;

	"${szy}" =
	{
		objects =
		{

			programs =
			{
				steam =
				{
					#variable.enable = true;
				};
				firefox.variable =
				{
					#enable = true;
				
					components.wivrn.enable = true;
				};
				chrome.variable.enable = true;
				#zsh.variable.enable = true;
			};

			/*template.programs =
			{
				browser.variable.default =
				{
					entry.any = "chrome";
				};
			};*/

			users.goos.variable =
			{
				enable = true;
				shell = pkgs.zsh;
			};

		};

		catalog =
		{
	
			programs =
			{
				zsh.enable = true;
				firefox =
				{
					enable = true;
					test = [ "hello" ];
				};

				default.browser = "chrome";
			};

		};

	};

}
