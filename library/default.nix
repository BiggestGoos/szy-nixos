inputs:
let

	internal = import ./internal inputs;

	directory = ./parts;

	createLibrary = { ... }@arguments:
	rec {

		inherit arguments;

		setArguments = new: createLibrary new;
		addArguments = new: createLibrary (arguments // new); # TODO: Add deep merge with priority and order
		__functor = self: addArguments;

	} // 
	(
		internal.importSzy
		{
			inherit arguments directory;
		}
	);

in
	createLibrary {}
