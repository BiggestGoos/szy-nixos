{

	inputs =
	{
  		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		szy.url = "/home/goos/Dev/szy-nixos";
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
				szy = inputs.szy.library { host.name = "test"; };
			};
			modules = 
			let
				home-manager.test.import = 
				{
					x = [ "home manager" ];
				};
			in
			[ 
	  			./configuration.nix 
				home-manager.test.import
				{
					nixpkgs.hostPlatform = "x86_64-linux";
				}
	  		];
    	};

  	};

}
