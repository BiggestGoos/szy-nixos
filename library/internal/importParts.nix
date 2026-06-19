{ inputs, internal, ... }:
let

	inherit (inputs.nixpkgs) lib;

	importParts' =
	{
		whole,
		arguments, 
		directory ? null,
		imports ? null,
		wholeName ? "final",
		filter ? null,
		reservedNames ? [],
	}@input:
	let

		defaultReservedNames =
		[
			"name"
			"content"
			"imports"
		];

		reservedNames = defaultReservedNames ++ (input.reservedNames or []);

		containsReserved = set:
		let
			attrNames = builtins.attrNames set;
		in
			!(lib.lists.mutuallyExclusive attrNames reservedNames);

		# Either directory or imports must be set, if both the imports takes precedence.
		parts =
		lib.trivial.throwIf ((directory == null) && (imports == null)) "Either directory or imports must be set!"
		(
			if (imports != null)
			then # Parts can be imported via a list of either paths to .nix files or a set, both containing a part
			(
				builtins.listToAttrs
				(
					builtins.map
					(
						value:
						{
							name = 
							if (builtins.isAttrs value)
							then value.name
							else lib.strings.removeSuffix ".nix" (lib.lists.last (builtins.split "/" (builtins.toString value)));
							inherit value;
						}
					) imports
				)
			)
			else # Parts can be imported via a path to a directory containing .nix files of parts
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

		whole' = 
		lib.attrsets.filterAttrs
		(
			name: value:
				value != {}
		)
		(
			lib.attrsets.mapAttrs'
			(
				name: value:
				let
					part' = 
					if (builtins.isAttrs value)
					then value
					else import value;

					argument = { inherit inputs lib arguments; "${wholeName}" = (whole // { inherit internal; }); };

					# If the part is a function, we call it, if not then we don't
					part = if (builtins.isFunction part') then (part' argument) else part';

					# We filter out parts with the given filter function
					result = 
					if (filter == null)
					then { result = true; }
					else filter part;

					# Parts can be very simple, only a single value, but if they are a set, they must place their content in 'content' or not use any of the reserved attrNames
					content = 
					if (!builtins.isAttrs part)
					then part
					else part.content or
					(
						if (containsReserved part)
						then {}
						else part
					);
					# Parts can import more parts with a list of sets or paths to parts
					imports = part.imports or [];

					finalContent = 
					if (imports == [])
					then content
					else
					(
						internal.attrsets.deepMergeList
						[
							content
							(
								importParts'
								{
									inherit whole arguments imports wholeName filter;
								}
							)
						]
					);

				in
				{
					name = part.name or name;
					value = 
					if result == true # The filter result
					then finalContent
					else {};
				}
			) parts
		);

	in
		whole';


in
rec {
	
	importParts =
	{
		arguments, 
		directory ? null,
		imports ? null,
		wholeName ? "final",
		filter ? null,
		reservedNames ? [],
	}:
	let

		whole = importParts'
		{
			inherit 
				whole
				arguments
				directory
				imports
				wholeName
				filter
				reservedNames
			;
		};

	in
		whole;

}
