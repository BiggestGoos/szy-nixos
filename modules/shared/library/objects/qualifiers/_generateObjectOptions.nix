{ szy, lib, config, ... }:
(szy config).objects.declare
{

	name = "generateObjectOptions";

	/*
		Data used to decide exactly where an option should be placed
	*/
	metaParameters =
	{

		template =
		{ final, ... }:
		{

			generateObjectOptions.namespace = lib.options.mkOption
			{
				type = lib.types.listOf lib.types.str;
				default = [ final.meta.name ];
			};

		};

		object =
		{ final, template, ... }:
		{

			generateObjectOptions =
			{

				name = lib.options.mkOption
				{
					type = lib.types.str;
					default = final.meta.name;
				};

				namespace = lib.options.mkOption
				{
					type = lib.types.listOf lib.types.str;
					default = template.meta.metaData.generateObjectOptions.namespace;
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
		Every object will get all data with its identifier and merge it, then append it to its data.
	*/
	defaultArguments =
	{ final, template, ... }:
	let
		dataList =  
		builtins.filter
		(data: final.meta.identifier == data.identifier)
		config."${szy}".meta.objects.generateObjectOptions.data;
		
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
			Data can be added as an identifier to an object and the data for that object
		*/
		"${szy}".meta.objects.generateObjectOptions =
		{

			data = lib.options.mkOption
			{
				type = 
				let
					module.options =
					{
						identifier =
						{
							name = lib.options.mkOption
							{
								type = lib.types.str;
							};
							template = lib.options.mkOption
							{
								type = lib.types.str;
							};
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
