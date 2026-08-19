{ szy, lib, arguments, ... }:
let

	outside.config = arguments.config or (builtins.throw "Either add config as argument to szy or supply your own config when calling utils functions!");

	output =
	{

		namespace = [ "${szy}" "objects" ];

		template =
		{

			namespace = output.namespace ++ [ "template" ];

			get =
			{
				config ? outside.config,
				identifier
			}:
			szy.lib.attrsets.getFromKeys
			{
				keys = output.template.namespace ++ identifier;
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
					output.template.get { inherit config identifier; }
			) list;

		};

	};

in
	output
