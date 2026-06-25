{ arguments, ... }:
{

	requiredArguments = [ [ "config" ] ];

	/*
		Qualifiers should follow this template:

		qualifierArgument:
		{ # can simply be a function but also allows a functor with extra data:
			extends = [ ... (extends added by the qualifier) ]; # optional
			__functor = self: 
			{
				identifier, (The identifier of the qualifiers target)
				config,
				data, (The old data)
			}:
			{
				Should be a set which contains the old data as well as modifications to it.
			}
		}
	*/

	# You can add additional qualifiers via the objects.qualifiers argument for szy!
	# They can either be in objects.qualifiers.* *.definition or *.template.
	content = (arguments.objects or {}).qualifiers or {};

	imports =
	[
		{
			name = "definition";
			imports =
			[
				./composable.nix
			];
		}
		{
			name = "template";
			imports =
			[
				./generateObjectOptions.nix
				./generateTemplateOptions.nix
			];
		}
	];
	
}
