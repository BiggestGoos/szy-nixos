{ lib, szy, ... }:
{

	content =
	{

		constant = 
		{ type, value, extra ? {} }: 
		szy.lib.attrsets.deepMerge
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

	};

}
