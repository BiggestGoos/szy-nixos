{

	description = "Szy, library for NixOS";

	inputs =
	{
		import-tree.url = "github:denful/import-tree";
	};

	outputs = inputs:
	let
		library = { nixpkgs }: import ./library (inputs // { inherit nixpkgs; });
	in
	{

		inherit library;


		# Move this into library as function

		/*
			Using import-tree we want to import all *.nix files in ./modules 
			that are not in a directory containing a file called default.nix 
			as well as not being in a directory called 'internal'.
		*/
		/*modules =
		let

			result = 
			import-tree
			(i:
				i.initFilter (lib.strings.hasSuffix ".nix")
			)
			(i:
				i.filterNot (lib.strings.hasInfix "internal")
			)
			(i:
			 
				We replace all files in directories with a default.nix file, except for default.nix, with {}.
				I would have used .filter but when I did I got relative paths which didn't work with builtins.readDir
			
				i.map
				(path:
					let
						filename = lib.lists.last (builtins.split "/" (builtins.toString path));
						directory = lib.strings.removeSuffix filename (builtins.toString path);
						files = builtins.readDir directory;
						defaultName = "default.nix";
						containsDefault = builtins.hasAttr defaultName files;
					in
					if (filename == defaultName)
					then path
					else if (!containsDefault)
					then path
					else {}
				)
			) ./modules;

		in
			result;*/

	};

}
