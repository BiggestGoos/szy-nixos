{ szy, lib, arguments, ... }:
let

	outside.config = arguments.config or (builtins.throw "Either add config as argument to szy or supply your own config when calling utils functions!");

	output =
	{

		namespace = [ "${szy}" "objects" ];

		resolveIdentifier = identifier:
		let
			isString = builtins.isString identifier;
			isListOfStrings = (builtins.isList identifier) &&
			(
				builtins.all (value: builtins.isString value) identifier
			);
		in
		if !(isString || isListOfStrings)
		then builtins.throw "The given identifier is not a real identifier!"
		else lib.lists.toList identifier;

		get =
		{
			config ? outside.config,
			identifier
		}:
		szy.lib.attrsets.getFromKeys
		{
			keys = output.namespace ++ identifier;
			object = config;
		};		

		testInherits =
		{
			config ? outside.config,
			identifier,
			template
		}@input:
		let
			object = output.get { inherit identifier; };
			template = output.template.resolveIdentifier input.template;
		in
		builtins.elem template
		(
			builtins.map
			(
				value:
					value.identifier
			) object.meta.allInherits
		);

		getList =
		{
			config ? outside.config,
			list
		}:
		builtins.map
		(
			identifier:
				output.get { inherit config identifier; }
		) list;

		template =
		{
			
			prefix = [ "template" ];
			namespace = output.namespace ++ output.template.prefix;

			resolveIdentifier = identifier':
			let
				identifier = output.resolveIdentifier identifier';
			in
			if (lib.lists.take 1 identifier) == output.template.prefix
			then identifier
			else output.template.prefix ++ identifier;

			getAllObjects =
			{
				config ? outside.config,
				identifier
			}:
			let
				testIdentifier = identifier;
				objects = szy.lib.attrsets.getFromKeys
				{
					keys = output.namespace ++ [ "meta" "objects" ];
					object = config;
				};
			in
			builtins.filter
			(
				identifier:
				let
					object = output.get { inherit identifier config; };
				in
				builtins.any
				(
					template:
						template.identifier == testIdentifier
				) object.meta.allInherits
			) objects;

			absolute =
			{

				getPath = identifier: identifierInner':
				let
					identifierInner = output.template.resolveIdentifier identifierInner';
					template = output.get { inherit identifier; };
					path = 
					(
						lib.lists.findFirst
						(
							value:
								value.identifier == identifierInner
						)
						[]
						template.meta.allInherits
					).path;
				in
					path;

				getFrom = identifier: prefix: identifierInner:
				szy.lib.attrsets.getFromKeys
				{
					keys = (lib.lists.toList prefix) ++ (output.template.absolute.getPath identifier identifierInner);
					object = output.get { inherit identifier; };
				};	

				setAt = identifier: identifierInner: input:
				szy.lib.attrsets.createFromKeys
				{
					keys = output.template.absolute.getPath identifier identifierInner;
					value = input;
				};	

			};

		};

	};

in
	output
