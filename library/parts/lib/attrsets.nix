{ szy, lib, ... }:
{

	content =
	{

		inherit (szy.internal.attrsets) 
			deepMerge 
			deepMergeList 
			mkOverride 
			mkDefault 
			mkForce 
			mkAbsoluteDefault 
			mkBreakoutPriority
		;

		createFromKeys = { keys, value ? {} }: lib.attrsets.setAttrByPath keys value;
		getFromKeys = { keys, object, default ? {}}: lib.attrsets.attrByPath keys default object;

	};

}
