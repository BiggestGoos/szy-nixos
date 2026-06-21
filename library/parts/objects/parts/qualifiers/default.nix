{ arguments, ... }:
{

	requiredArguments = [ [ "config" ] ];

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

	# You can add additional qualifiers via the objects.qualifiers argument for szy!
	content = (arguments.objects or {}).qualifiers or {};

	imports =
	[
		./composable.nix
	];
	
}
