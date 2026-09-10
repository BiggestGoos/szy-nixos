node:
let
	flattenTree = node: prefix:
    let
      	children = node.branches or {};
      	keys = builtins.attrNames children;

      	pathsFromChildren = builtins.concatLists (map (k:
        let
        	child = children.${k};
        	step = {
            	name = k;
            	configuration = child.configuration or {};
				globalConfiguration = child.globalConfiguration or {};
        	};
        in
          	flattenTree child (prefix ++ [ step ])
      	) keys);

      	currentIsLeaf = keys == [];
      	currentIsResolve = node.resolveTo or false;
    in
      	builtins.concatLists [
        	pathsFromChildren
        	(if currentIsLeaf || currentIsResolve then [ prefix ] else [])
      	];
in
	flattenTree node [ ]

