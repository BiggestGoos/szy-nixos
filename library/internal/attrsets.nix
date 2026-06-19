{ lib, ... }:
{

	attrsets =
	rec {	

		inherit (lib)
			mkOverride
			mkDefault
			mkForce
		;

		/*
			Set priority to the actual default value of priorities
		*/
		mkAbsoluteDefault =
		let
			absoluteDefaultPriority = 100;
		in
			mkOverride absoluteDefaultPriority;

		/*
			If you want a value to have a priority, use this to breakout that priority, otherwise it will be removed with a deepMerge.
		*/
		mkBreakoutPriority = mkAbsoluteDefault;

		/*
			deepMerge takes two sets and returns one set which is the result of merging the given sets. Right set takes precedence.
			Sets and lists are merged, lists are merged r.list ++ l.list. Overrides are taken into account, not orders though.
		*/
		deepMerge = lset: rset:
		let
			attrNames =
			let
				assertIsSet = set: (lib.trivial.throwIfNot (builtins.isAttrs set) "Values passed to 'deepMerge' has to be of type attrset! Value type passed: { ${builtins.typeOf set} }");
			in
			{
				l = (assertIsSet lset) (builtins.attrNames lset);
				r = (assertIsSet rset) builtins.attrNames rset;
			};
			conflicts = lib.lists.intersectLists attrNames.l attrNames.r;
			baseMerge = lset // rset;

			values = 
			builtins.listToAttrs
			(
				builtins.map
				(
					name:
					let
						lvalPre = { name = "l"; value = lset."${name}"; };
						rvalPre = { name = "r"; value = rset."${name}"; };

						valuesList = lib.filterOverrides [ lvalPre rvalPre ];

						values = 
						builtins.listToAttrs
						(
							builtins.map
							(
								value:
								{
									name = value.name;
									value = value.value;
								}
							) valuesList
						);

						lval = values.l;
						rval = values.r;

						bothAre = func: (func lval) && (func rval);
					in
					{
						inherit name;
						value = 
						if ((builtins.length valuesList) == 1)
						then (builtins.head valuesList).value
						else
						(
							if (bothAre builtins.isList)
							then rval ++ lval
							else if (bothAre builtins.isAttrs)
							then deepMerge lval rval
							else rval
						);
					}
				) conflicts
			);

		in
			baseMerge // values;

		/*
			deepMergeList deeply merges a list of sets. The further back in the list the higher the priority.
		*/
		deepMergeList = list: lib.lists.foldl deepMerge {} list;

	};

}
