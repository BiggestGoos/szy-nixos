{ szy, config, lib, ... }:
let
	szy' = szy config;
in
szy'.objects.make.template
{

	name = "default";

	template.variable' =
	{ meta, variable, ... }:
	{

		default =
		{

			/*
				Here you can select which object's identifier will be default for which type. 
				If types == {} then this can be set to an identifier directly.
			*/
			entry = lib.options.mkOption
			{
				type =
				let
					single = lib.types.nullOr (lib.types.either (lib.types.str) (lib.types.listOf lib.types.str));
					multiple' = (lib.types.attrsOf single);
					multiple = lib.types.addCheck multiple'
					(
						value:
						let
							newAttrNames = builtins.attrNames value;
							allowedAttrNames = builtins.attrNames variable.default.types;
							subtracted = lib.lists.subtractLists allowedAttrNames newAttrNames;
						in
						if subtracted == []
						then true
						else builtins.throw "Type error: Can't set default entry for template '${meta.prettyName}' with ${builtins.toJSON newAttrNames} as they are not in ${builtins.toJSON allowedAttrNames}"
					);
				in
				if variable.default.types == {}
				then single 
				else multiple;
				default = null;
			};

			/*
				Here you can decide what types of default values exist. Each type's name comes from the
				key name in the dictionary. The value is a predicate function that decides if a given object
				fits into that type.
			*/
			types = lib.options.mkOption
			{
				type = lib.types.attrsOf (lib.types.functionTo lib.types.bool);
				default = {};
			};

			/*
				The namespace in which to primarily search for objects.
			*/
			namespace = lib.options.mkOption
			{
				type = lib.types.either (lib.types.str) (lib.types.listOf lib.types.str);
				default = [];
			};

		};

	};

	template.variable =
	{ variable, ... }:
	{

		/*
			Here we set up the entries to match the structure of types
		*/
		default.entry = lib.mkIf (variable.default.types != {})
		(
			lib.attrsets.mapAttrs
			(
				name: value:
					lib.mkOptionDefault null
			) variable.default.types
		);

	};

	template.absolute.constant' =
	{ meta, getFrom, ... }:
	let

		self = getFrom "variable" "default";

		inherit (self.default) entry types;
		namespace = lib.lists.toList self.default.namespace;

		objects = meta.allObjects;

		filterObjects = predicate:
		builtins.filter
		(
			identifier:
			let
				object = szy'.objects.utils.get { inherit identifier; };
			in
				object.constant.enabled && (predicate object)
		) objects;

		findWanted = identifier:
		if builtins.elem (namespace ++ (lib.lists.toList identifier)) objects
		then namespace ++ (lib.lists.toList identifier)
		else
		(
			if builtins.elem (lib.lists.toList identifier) objects
			then lib.lists.toList identifier
			else null
		);

		findFirst = predicate:
		let
			objects = filterObjects predicate;
		in
		if objects == []
		then null
		else builtins.head objects;

		default =
		if types == {}
		then
		(
			let
				wanted =
				if entry == null
				then null
				else findWanted entry;

				identifier = 
				if wanted == null
				then findFirst (x: true)
				else wanted;
			in
			if identifier != null
			then szy'.objects.utils.get { inherit identifier; }
			else null
		)
		else
		(
			lib.attrsets.mapAttrs
			(
				name: predicate:
				let
					curEntry = entry.${name} or null;

					wanted =
					if curEntry == null
					then null
					else findWanted curEntry;
	
					identifier = 
					if wanted == null
					then findFirst predicate
					else wanted;
				in
				if identifier != null
				then szy'.objects.utils.get { inherit identifier; }
				else null
			) types
		);

	in
	{

		/*
			We attempt to find the most fitting object based on what is set in entry. If noting is set or the object can't be found then the
			first-best object that does exist and fits the predicate of the type is selected. In the future it might be better to e.g. throw an
			error when we try to set an entry but it can't be found.
		*/
		default = lib.options.mkOption
		{
			type = lib.types.nullOr (lib.types.either lib.types.attrs (lib.types.nullOr (lib.types.attrsOf lib.types.attrs)));
			readOnly = true;
			inherit default;
		};

	};

}
