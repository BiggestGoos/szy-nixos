{ szy, lib, config, ... }:
let

	template = (szy config).objects.utils.get { identifier = [ "template" "generateOptions" ]; };

	getData = meta:
	let
		dataList =  
		builtins.filter
		(
			data: 
				meta.identifier == data.identifier
		) template.variable.data;
		
		/*
			At the moment this will try to merge multiple dataparts for the same object. It is not very good though
			as it doesn't use the module system for this.
		*/
		data = 
		szy.lib.attrsets.deepMergeList # TODO: I would like to avoid this, try to find way to use module system!
		#lib.mkMerge # Does not work
		(
			builtins.map
			(
				data:
					data.data
			) dataList
		);
	in
		data;

in
(szy config).objects.make.template
{

	name = "generateOptions";

	absolute.variable =
	{ meta, ... }: getData meta;

	template.absolute.variable =
	{ meta, ... }:
	if meta.identifier != [ "template" "generateOptions" ]
	then getData meta
	else {};

	template.variable' =
	{

		data = lib.options.mkOption
		{
			type = 
			let
				module.options =
				{
					identifier = lib.options.mkOption
					{
						type = lib.types.listOf lib.types.str;
					};
					data = lib.options.mkOption
					{
						type = lib.types.attrs;
					};
				};
			in
			lib.types.listOf (lib.types.submoduleWith { modules = [ module ]; });
		};

	};

}
