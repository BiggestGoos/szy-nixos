{ lib, ... }:
let

	absoluteDefaultPriority = 100;

	overrideType = "szy-override";

	isOverride = value: ((value._type or "") == overrideType);

	getPriority = value:
	if (isOverride value)
	then value.priority or absoluteDefaultPriority
	else absoluteDefaultPriority;

	getContent = value:
	if (isOverride value)
	then value.content
	else value;

	stripOverrideRecursive = value:
	let

		content = getContent value;

		strippedSet = 
		lib.attrsets.mapAttrs
		(
			name: value:
				stripOverrideRecursive value
		) content;

	in
	if (!(builtins.isAttrs content))
	then content
	else strippedSet;

	/*
		I had to create my own function for filtering overrides as the nixpkgs.lib one strips the override property when filtering.
		This means that when merging a list of attributes, the override property will be lost along the way. A way to resolve this is
		to simply not strip the override property until after everything is merged.
	*/
	filterOverrides = l: r:
	let

		lprio = getPriority l.value;
		rprio = getPriority r.value;

		getResult = value: thisPrio: otherPrio:
		if (thisPrio <= otherPrio) # Lower prio => higher prio (for some reason)
		then 
		[ value ]
		else [];

		result =
		(
			getResult l lprio rprio
		) ++
		(
			getResult r rprio lprio
		);

	in
		result;

in
rec {

	attrsets =
	let

		deepMerge' = lset: rset:
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

						valuesList = filterOverrides lvalPre rvalPre;

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

						# Since it might be the case that one value is an override set while the other is a regular value we need to unwrap, do operation, and wrap again for it to work.

						bothAre = func: (func (getContent lval)) && (func (getContent rval));
						appendLists = l1: l2:
						let
							l1val = getContent l1;
							l2val = getContent l2;
						in
							attrsets.mkOverride (getPriority l1) (l1val ++ l2val);

						mergeSets = s1: s2:
						let
							s1val = getContent s1;
							s2val = getContent s2;
						in
							attrsets.mkOverride (getPriority s1) (deepMerge' s1val s2val);
					in
					{
						inherit name;
						value = 
						if ((builtins.length valuesList) == 1)
						then (builtins.head valuesList).value
						else
						(
							if (bothAre builtins.isList)
							then appendLists rval lval
							else if (bothAre builtins.isAttrs)	
							then mergeSets lval rval				
							else rval						
						);											
					}
				) conflicts
			);

		in
			baseMerge // values;

	in
	rec {

		mkOverride = priority: content:
		{
			_type = overrideType;
			inherit priority content;
		};

		mkDefault = mkOverride 1000;
		mkForce = mkOverride 50;

		/*
			Set priority to the actual default value of priorities
		*/
		mkAbsoluteDefault = mkOverride absoluteDefaultPriority;

		/*
			deepMerge takes two sets and returns one set which is the result of merging the given sets. Right set takes precedence.
			Sets and lists are merged, lists are merged r.list ++ l.list. Overrides are taken into account, not orders though.
		*/
		deepMerge = lset: rset: stripOverrideRecursive (deepMerge' lset rset);

		/*
			deepMergeList deeply merges a list of sets. The further back in the list the higher the priority.
		*/
		deepMergeList = list: stripOverrideRecursive (lib.lists.foldl deepMerge' {} list);

	};

}
