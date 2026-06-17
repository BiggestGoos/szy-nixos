{ identifier, lib, utils, importLib, helper, ... }@gInputs:
let

	composable = import ./composable.nix gInputs;

in
{

	/*
		Qualifiers should follow this template:

		qualifierArgument:
		{
			extends = [ ... (extends added by the qualifier) ];
			__functor = self: 
			{
				identifier, (The definitions identifier)
				config,
				data, (The old data)
			}:
			{
				Should be a set which contains the old data as well as modifications to it.
			}
		}
	*/

	inherit composable;
	
}
