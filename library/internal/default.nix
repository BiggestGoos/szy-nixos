inputs:
let

	inherit (inputs.nixpkgs) lib;

	importParts = (import ./importParts.nix { inherit inputs internal; });
	attrsets = (import ./attrsets.nix { inherit inputs; });

	internal = attrsets.attrsets.deepMergeList
	[
		importParts
		attrsets
	];

	szyInternal = internal //
	{

		importSzy = 	
		{
			arguments,
			directory,
		}:
		let
			wholeName = "szy";
		in
		internal.importParts
		{
			inherit arguments directory wholeName;
			filter = part:
			let
				isSublist = main: sub:
				let
					intersection = lib.lists.intersectLists main sub;
				in
					(builtins.length intersection) == (builtins.length sub);

				argumentNames = builtins.attrNames arguments;
				requiredArguments = part.requiredArguments or [];
				hasRequiredArguments = isSublist argumentNames requiredArguments;
			in
			{
				result = hasRequiredArguments;
				warning = 
				let
					missingArguments = lib.lists.subtractLists argumentNames requiredArguments;
				in
					"The required arguments ${builtins.toJSON missingArguments} for '${wholeName}' part '${part.name}' are not set!";
			};

		};

	};

in
	szyInternal
