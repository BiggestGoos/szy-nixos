{

	inputs =
	{
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		szy.url = "../";
	};

	outputs = 
	{ 
		self, 
		nixpkgs,
		...
	}@inputs: 
	{

		nixosConfigurations.test = 
		nixpkgs.lib.nixosSystem 
		{
			specialArgs = 
			{
				szy = inputs.szy.library.addArguments 
				{ 
					configType = "system";
					host =
					{
						name = "test";
						system = "x86_64-linux";
					};
				};
			};
			modules =
			(inputs.szy.modules.system) ++
			[
				./configuration.nix
			];

		};

	};

}
