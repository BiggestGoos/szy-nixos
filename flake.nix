{

	description = "Szy, library for NixOS";

	inputs =
	{
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs = inputs:
	let
		library = import ./library inputs;
	in
	{

		inherit library;

		modules =
		let
			importPath = path: library.lib.imports.recursive path;
			shared = importPath ./modules/shared;
		in
		{

			system = (importPath ./modules/system) ++ shared;
			user = (importPath ./modules/user) ++ shared;
			
		};

	};

}
