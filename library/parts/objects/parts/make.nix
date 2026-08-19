{ szy, lib, arguments, ... }:
let

	inherit (szy.objects) utils;

	/*
		Make an object.

		If namespace has a head value of "template" then the object is a template.
	*/
	make = 
	inputs':
	let

		data =
		{
			data' = [ {} ];
			data = [ {} ];

			constant' = [ {} ];
			constant = [ {} ];
		};

		inputs = szy.lib.functions.followSchema
		(
			final:
			let
				inherit (final) namespace;
				isTemplate =
				if !(builtins.isList namespace && namespace != [])
				then false
				else (builtins.head namespace) == "template";
			in
			{
				name = {};
				namespace = [ [] ];
				
				/*
					A list of either string or list of string. Just a string will be
					interpreted as a list of one string.
				*/
				templates = [ [] ];

				/*
					This schema decides how this object includes templates.
				*/
				schema = [ {} ];

				enable = [ (!isTemplate) ];

				private = data;

				output =
				{
					config = [ {} ];
					options = [ {} ];
					imports = [ {} ];
				};

			} // data
		) inputs';

		# TODO: The way this should work is that each object is only responsible for consolidating specifically the templates that it itself declares use of.
		# Then this function should resolve this declaration by getting each declared templates schema and in-place inserting where that specific template
		# is used in this schema.
		/*resolveSchema = schema: templates:
		let
			
			findTemplates = schema:
			builtins.concatLists
			(
				lib.attrsets.mapAttrsToList
				(
					name: value:
					if name == "inherits"
					then
					(
						builtins.map
						(
							template:
								lib.lists.toList template
						) value
					)
					else
					(
						if !(builtins.isAttrs value)
						then [ (lib.lists.toList value) ]
						else findTemplates value
					)
				) schema
			);

			usedTemplates =  findTemplates schema;

			# TODO: Test templates against usedTemplates. If usedTemplates contains more templates than templates then we know
			# that something is wrong. Either there are multiple uses of one template or 

		in
		{
			templates = findTemplates schema;
		};*/

		templates' =
		builtins.map
		(
			identifier:
				lib.lists.toList identifier
		) inputs.templates;

		templates = utils.template.getList { list = templates'; };

		schema = resolveSchema inputs.schema templates;

		identifier = inputs.namespace ++ [ inputs.name ];

	in
	{

		options = 
		let
			namespace = szy.objects.utils.namespace ++ identifier;

			inherit (szy.lib.options) constant;
		in
		lib.attrsets.setAttrByPath namespace
		(
			{

				meta =
				{

					identifier = constant
					{
						type = lib.types.listOf lib.types.str;
						value = identifier;
					};

					templates = constant
					{
						type = lib.types.listOf (lib.types.listOf lib.types.str); # TODO: Add validation that these are real templates
						value = templates';
					};

					data' = constant
					{
						type = szy.lib.options.types.callable;
						value = lib.trivial.toFunction inputs.data';
					};

					schema = constant
					{
						type = lib.types.attrs;
						value = schema;
					};

				};

			}
		);

	};

in
{

	requiredArguments = [ [ "config" ] ];

	content = make;

}
