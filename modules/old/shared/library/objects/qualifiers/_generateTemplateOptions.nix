{ szy, lib, config, ... }:
(szy config).objects.declare
{

	name = "generateTemplateOptions";

	/*
		Data used to decide exactly where an option should be placed
	*/
	metaParameters =
	{

		template =
		{ final, ... }:
		{

			generateTemplateOptions =
			{

				name = lib.options.mkOption
				{
					type = lib.types.str;
					default = final.meta.name;
				};

				generateOption = lib.options.mkOption
				{
					type = lib.types.bool;
					default = true;
				};

			};

		};

	};

	/*
		Every template will get all data with its identifier and merge it, then append it to its data.
	*/
	templateArguments =
	{ final, ... }:
	let
		dataList =  
		builtins.filter
		(data: final.meta.identifier == data.identifier)
		config."${szy}".meta.objects.generateTemplateOptions.data;
		
		data = 
		szy.lib.attrsets.deepMergeList
		(
			builtins.map
			(
				data:
					data.data
			) dataList
		);
	in
		data;

	options =
	{ final, ... }:
	{

		/*
			Data can be added as an identifier to a template and the data for that template
		*/
		"${szy}".meta.objects.generateTemplateOptions =
		{

			data = lib.options.mkOption
			{
				type = 
				let
					module.options =
					{
						identifier = lib.options.mkOption
						{
							type = lib.types.str;
						};
						data = lib.options.mkOption
						{
							type = lib.types.attrs;
							default = {};
						};
					};
				in
					lib.types.listOf (lib.types.submoduleWith { modules = [ module ]; });
				default = [];
			};

		};

	};

}
