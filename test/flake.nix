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
				szy = inputs.szy.library { hostname = "test"; };
			};
			modules = 
			[ 
	  			./configuration.nix 
				{
					nixpkgs.hostPlatform = "x86_64-linux";
				}
	  		];
    	};

  	};

}
