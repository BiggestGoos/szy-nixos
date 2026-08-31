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


		};

	};

in
	output
