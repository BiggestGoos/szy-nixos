{ self, lib }:
{

	mkConfiguration =
	{ hostname, system, timeZone, locale, rawRoot }:
	let
		szy = self { inherit hostname rawRoot; };
		inherit (szy) config;
	in
	{

		"${hostname}" = 
		let
			sharedArgs =
			{
				inherit (self) inputs; 
				inherit szy system;
			};
		in
		lib.nixosSystem 
		{

			specialArgs = sharedArgs // { systemConfig = true; };
			modules = [ szy.import.modules.path szy.import.modules.system szy.import.modules.shared ] ++ [
				self.inputs.disko.nixosModules.disko
				(szy.utils.fromRoot "hosts/${hostname}")
				self.inputs.home-manager.nixosModules.home-manager
				{
					home-manager = 
					{
	    				useUserPackages = true;
						backupFileExtension = "backup";
	    				users = builtins.mapAttrs (name: value: (import value.path)) config."${szy}".users.homeManagerPaths;
						extraSpecialArgs = sharedArgs // { systemConfig = false; };
						sharedModules = [ szy.import.modules.users.user.path szy.import.modules.user szy.import.modules.shared ];
					};
				}
			] ++ [ {

				"${szy}" = {

					inherit timeZone locale;

				};

			} ];

		};

	};

}
