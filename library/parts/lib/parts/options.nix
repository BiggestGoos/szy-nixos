{ lib, szy, ... }:
{

	content =
	rec {

		constant = 
		{ type, value, extra ? {} }: 
		szy.lib.attrsets.deepMergeList
		[ 
			(
				lib.options.mkOption 
				{
					type = type;
					readOnly = true;
					default = value;
				}
			) 
			extra 
		];

		types =
		rec {

			callable' = type: lib.types.either type (lib.types.functionTo type);
			callable = callable' lib.types.attrs;

			anything = lib.types.mkOptionType # Fork from nixpkgs, original in nixpkgs/lib/types.nix
			{
				name = "anything";
				description = "anything";
				descriptionClass = "noun";
				check = value: true;
				merge =
      			loc: defs:
      			let
        			getType =
          			value: if builtins.isAttrs value && lib.strings.isStringLike value then "stringCoercibleSet" else builtins.typeOf value;

        			# Returns the common type of all definitions, throws an error if they
        			# don't have the same type
        			commonType = lib.lists.foldl' 
					(
          				type: def:
	          			if getType def.value == type 
						then type
						else builtins.throw "The option `${lib.options.showOption loc}' has conflicting option types in ${lib.options.showFiles (lib.options.getFiles defs)}"
        			) (getType (builtins.head defs).value) defs;

        			mergeFunction =
          			{
            			# Recursively merge attribute sets
            			set = (lib.types.attrsOf anything).merge;
						# CHANGE: Append lists
						list = (lib.types.listOf anything).merge;
            			# This is the type of packages, only accept a single definition
            			stringCoercibleSet = lib.options.mergeOneOption;
            			lambda =
              			loc: defs: arg:
              			anything.merge (loc ++ [ "<function body>" ]) 
						(
                			builtins.map 
							(
								def: 
								{
                  					file = def.file;
                  					value = def.value arg;
                				}
							) defs
              			);
            			# Otherwise fall back to only allowing all equal definitions
          			}.${commonType} or lib.options.mergeEqualOption;
      			in
      				mergeFunction loc defs;
  			};

		};

	};

}
