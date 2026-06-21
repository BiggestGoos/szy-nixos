inputs:
let

	inherit (inputs.nixpkgs) lib;

	importParts = (import ./importParts.nix { inherit inputs internal; });
	attrsets = (import ./attrsets.nix { inherit lib; });

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
				requiredArguments = part.requiredArguments or [];
				supportedConfigType = part.supportedConfigType or null;

				configType = arguments.configType or null;
				isSupportedConfigType = 
				if (configType == null || supportedConfigType == null)
				then true
				else supportedConfigType == configType;

				hasRequiredArguments = 
				lib.lists.all
				(
					argument':
					let
						argument = lib.lists.toList argument';
					in
						lib.attrsets.hasAttrByPath argument arguments
				) requiredArguments;
			in
				isSupportedConfigType && hasRequiredArguments;

			reservedNames =
			[
				"requiredArguments"
				"supportedConfigType"
			];
		};

	};

in
	szyInternal
