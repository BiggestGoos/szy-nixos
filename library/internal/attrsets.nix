{ inputs, ... }:
let
	inherit (inputs.nixpkgs) lib;
in
{

	attrsets =
	rec {	

		/*
			deepMerge takes two sets and returns one set which is the result of merging the given sets. Right set takes precedence.
			Sets and lists are merged, lists are merged r.list ++ l.list.
		*/
		deepMerge = lset: rset:
		let
			attrNames =
			{
				l = builtins.attrNames lset;
				r = builtins.attrNames rset;
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
						lval = lset."${name}";
						rval = rset."${name}";
						bothAre = func: (func lval) && (func rval);
					in
					{
						inherit name;
						value = 
						if (bothAre builtins.isList)
						then rval ++ lval
						else if (bothAre builtins.isAttrs)
						then deepMerge lval rval
						else rval;
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
