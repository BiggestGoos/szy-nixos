inputs:
let

	internal = import ./internal inputs;

	directory = ./parts;

	createLibrary = { ... }@arguments:
	internal.attrsets.deepMerge
	(
		rec {

			inherit arguments;

			setArguments = new: createLibrary new;
			addArguments = new: createLibrary (internal.attrsets.deepMerge arguments new);
			__functor = self: addArguments;

		}
	)
	(
		internal.importSzy
		{
			inherit arguments directory;
		}
	);

in
	createLibrary {}
