{ szy, lib, ... }:
let
	
	/*
		The default values for all the determine* functions:

		creates this structure:

		<namespace>.<template-name> =
		{
			...
			freeformType: any value can be set
			...
			final = template.data (The final config-data of the template)
		}

		And then sets the templates data attribute to the previous set
		without the 'final' attribute. Thus you can set any and all options
		of the template via the generated option.
	*/
	
	determineNamespaceDefault = template: [ template.meta.metaData.generateTemplateOptions.name ];

	determineOptionDefault = template:
	let
		module =
		{
			freeformType = lib.types.anything;
										
			options =
			{
				final = szy.lib.options.constant
				{
					type = lib.types.attrs;
					value = template.data;
				};
			};
		};
	in
	{
		type = lib.types.submoduleWith { modules = [ module ]; };
	};

	determineDataDefault = template: data: builtins.removeAttrs data [ "final" ];

	/*
		Generate a set of options for all templates extending a template. Options can be used to determine exactly how:

		- namespace: The namespace/key list where the base of the options will be placed.
		- determineNamespace: A function taking a template. Should return a sub-namespace 
		that says where exactly the option for that template should be placed. 
		- determineOption: A function taking a template. Should return a set in the form of
		an option. This option is used as the type for all options of each template. 
		- readOnly: If true then we won't set any data. This means that any options created
		in 'determineOption' will have no effect. If false the the data is used to affect the
		templates.
		- determineData: A function taking the template and config data gotten from the option. 
		Used to modify the data from the options into such a form that the data fits
		in the templates data attribute. Optional return value is null. If that is returned then 
		the template doesn't get its data set.
		- inSzy: If true then the szy identifier will be appended to the start of the namespace
		used when creating the options. If false then not that.
		- filter: A function taking a template and returning true if that template should get an
		option. If readOnly is false then the filter can only be dependant on constant data.
	*/
	generateTemplateOptions =
	{
		namespace,
		determineNamespace ? determineNamespaceDefault,
		determineOption ? determineOptionDefault,
		readOnly ? false,
		determineData ? determineDataDefault,
		inSzy ? true,
		filter ? (template: true),
	}:
	{

		extends = [ "generateTemplateOptions" ];

		__functor = self:
		{
			identifier,
			config,
			data,
		}@input:
		let
			namespace' = (lib.lists.optional inSzy "${szy}") ++ namespace;

			templates' = szy.objects.utils.template.getAllExtending { inherit config identifier; };

			/*
				All templates extending the template. 
			*/
			templates =
			builtins.map
			(
				template:
				{
					namespace = determineNamespace template;
					value = template;
				}
			)
			(
				builtins.filter
				filter
				(
					builtins.filter
					(
						template:
							template.meta.metaData.generateTemplateOptions.generateOption
					)
					(
						builtins.map
						(
							identifier:
								szy.objects.utils.template.get { inherit config identifier; }
						) templates'
					)
				)
			);

		in
		szy.lib.attrsets.deepMergeList
		[
			data
			{
				/*
					Here we create the options exposed to the user.
					As described, the namespace in which each option gets placed is determined
					per template as well as the option set which decides how the options look.
				*/
				options = 
				lib.attrsets.setAttrByPath namespace'
				(
					szy.lib.attrsets.deepMergeList
					(
						builtins.map
						(
							template:
							let
								option = determineOption template.value;
							in
								lib.attrsets.setAttrByPath template.namespace (lib.options.mkOption option)
						) templates
					)
				);
			}
			{
	
				config = 
				if (readOnly)
				then {}
				else
				{

					"${szy}".meta.objects.generateTemplateOptions.data = 
					builtins.filter
					(
						data:
							data.data != null
					)
					(
						builtins.map
						(
							template:
							let
								data' = lib.attrsets.attrByPath (namespace' ++ template.namespace) {} config;
								data = determineData template.value data';
							in
							{
								inherit (template.value.meta) identifier;
								inherit data;
							}
						) templates
					);

				};

			}
		];
	};

in
	generateTemplateOptions
