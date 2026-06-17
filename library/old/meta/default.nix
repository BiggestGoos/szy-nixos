{ lib, ... }:
let

	# Can identify lists and sets containing just one "flat" type as, e.g. "list, string".
	typeOf = input: 
	let
		baseType = builtins.typeOf input;
		resolvedType = if (builtins.elem baseType [ "set" "list" ]) then
			baseType + innerSuffix
		else
			baseType;

		innerSuffix = 
		let
		
			list = if (baseType == "list") then input else (lib.attrsets.attrValues input);

			headType = (builtins.typeOf (builtins.head list));

			allSame = lib.lists.all (value: (builtins.typeOf value) == headType) list;

		in
			if (list == [] || !allSame) then "" else ", ${headType}";
	in
		resolvedType;

	# Naive
	compareTypes = lType: rType:
	let
		nestRemover = type: builtins.head (lib.strings.splitString "," type);
	in
		if (lType == rType) then true else (if ((nestRemover lType) == (nestRemover rType)) then true else false);

in
{

# Maybe create an assert function and move all "callerData" things into one set called "callerData", call the "callerData" function "typeCheck" or something like that.

	# Metadata about the "caller", e.g. data about the calling location or the "namespace" of the caller.

	callerData = 
	let

		dataValues = {
			config = typeOf {};
			path = typeOf ./.;
			namespace = typeOf [ "string" ];
		};
	
	in
	rec {

		typeCheckData = 
		data:
			lib.attrsets.filterAttrs 
			(name: value: 
			let
				result = 
					(lib.asserts.assertMsg 
						(builtins.hasAttr name dataValues)
						"callerData value \"${name}\" does not exist."
					) && (if (name == "config") then true else # There is an infinite recursion if we try to check the type of config
					(lib.asserts.assertMsg 
						(compareTypes dataValues."${name}" (typeOf value))
						"callerData value of \"${name}\" { ${builtins.toJSON value} } is the wrong type. Correct type: \"${dataValues."${name}"}\", Used type: \"${typeOf value}\"."
					));
			in
				result
			) data;

		testData = 
		{
			data,
			requiredFields ? []
		}:
		let
			resolvedData = typeCheckData data;
		in
			if (lib.lists.all 
			(value: 
				lib.asserts.assertMsg 
				(builtins.elem value (builtins.attrNames dataValues)) 
				"The required field \"${value}\" is not a real field."
			) requiredFields) 
			then 
				(lib.lists.naturalSort (lib.lists.intersectLists (requiredFields) (builtins.attrNames resolvedData))) == (lib.lists.naturalSort (requiredFields))
			else false;
	
		assertData =
		{
			data,
			requiredFields ? []
		}@inputs:
			lib.asserts.assertMsg
			(testData inputs)
			"The callerData { ${builtins.toJSON data} } did not contain all the required fields { ${builtins.toJSON requiredFields} }.";

		__functor = self: assertData;

	};

}
