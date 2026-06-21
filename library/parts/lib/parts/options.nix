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

	};

}
