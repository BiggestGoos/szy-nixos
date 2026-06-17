{ inputs, internal, ... }:
let
	inherit (inputs.nixpkgs) lib;
in
rec {
	
	importParts =
	{
		arguments, 
		directory ? null,
		imports ? null,
		wholeName ? "final",
		filter ? null
	}:
	let

		# Either directory or imports must be set, if both the imports takes precedence.
		parts =
		lib.trivial.throwIf ((directory == null) && (imports == null)) "Either directory or imports must be set!"
		(
			if (imports != null)
			then
			(
				builtins.listToAttrs
				(
					builtins.map
					(
						path:
						{
							name = lib.strings.removeSuffix ".nix" (lib.lists.last (builtins.split "/" (builtins.toString path)));
							value = path;
						}
					) imports
				)
			)
			else
			(
				lib.attrsets.mapAttrs
				(
					name: value:
						directory + "/${name}"
				)
				(
					lib.attrsets.filterAttrs
					(
						name: value: 
							value == "directory"
					) (builtins.readDir directory)
				)
			)
		);

		whole = 
		lib.attrsets.filterAttrs
		(
			name: value:
				value != {}
		)
		(
			lib.attrsets.mapAttrs
			(
				name: value:
				let
					part = import value { inherit inputs; "${wholeName}" = (whole // { inherit arguments internal; }); };
					result = 
					if (filter == null)
					then { result = true; }
					else filter (part // { inherit name; });

					content = part.content or null;
					imports = part.imports or [];

					finalContent = internal.attrsets.deepMergeList
					[
						content
						(
							importParts
							{
								inherit arguments imports;
							}
						)
					];

				in
				if result.result == true
				then finalContent
				else (lib.warn (result.warning or "Filter for part '${name}' of '${wholeName}' failed!") + "'${name}' will not be included in '${wholeName}'.") {}
			) parts
		);

	in
		whole;

}
