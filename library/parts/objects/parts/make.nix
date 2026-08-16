{ szy, lib, arguments, ... }:
let

	make = 
	inputs':
	let

		inputs = szy.lib.functions.followSchema
		(
			final:
			{
				name = {};
				namespace = [ [ ] ];

				templates = {};

				enabled = [ (!final.template) ];
				template = [ false ];

				data' = [ {} ];
				data = [ {} ];

				constant' = [ {} ];
				constant = [ {} ];

				output =
				{
					config = [ {} ];
					options = [ {} ];
					imports = [ {} ];
				};
			}
		)
		inputs';

		identifier = inputs.namespace ++ [ inputs.name ];

	in
	{

		options = 
		let
			namespace = szy.objects.utils.namespace ++ identifier;
		in
		lib.attrsets.setAttrByPath namespace
		{

		};

	};

in
{

	requiredArguments = [ [ "config" ] ];

	content = make;

}
