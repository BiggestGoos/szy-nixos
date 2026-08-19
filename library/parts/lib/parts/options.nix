{ lib, szy, ... }:
{

	content =
	{

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

		};

	};

}
