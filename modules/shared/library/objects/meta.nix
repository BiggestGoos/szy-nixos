{ szy, lib, config, ... }:
let
	inherit (szy.objects) utils;
in
{

	options =
	szy.lib.attrsets.createFromKeys
	{
		keys = utils.namespace;
		value.meta =
		{

			objects = lib.options.mkOption
			{
				type = lib.types.listOf (lib.types.listOf lib.types.str);
				default = [];
			};

			templates = lib.options.mkOption
			{
				type = lib.types.listOf (lib.types.listOf lib.types.str);
				default = [];
			};

		};
	};

}
