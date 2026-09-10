{ szy, lib, ... }:
let
	
	/*
		The default values for all the determine* functions:

		creates this structure:

		<namespace>.<template-name>.<object-name> =
		{
			...
			freeformType: any value can be set
			...
			final = object.data (The final config-data of the object)
		}

		And then sets the objects data attribute to the previous set
		without the 'final' attribute. Thus you can set any and all options
		of the object via the generated option.
	*/
	
	determineNamespaceDefault = object: object.meta.metaData.generateObjectOptions.namespace ++ [ object.meta.metaData.generateObjectOptions.name ];

	determineOptionDefault = object:
	let
		module =
		{
			freeformType = lib.types.anything;
										
			options =
			{
				final = szy.lib.options.constant
				{
					type = lib.types.attrs;
					value = object.data;
				};
			};
		};
	in
	{
		type = lib.types.submoduleWith { modules = [ module ]; };
	};

	determineDataDefault = object: data: builtins.removeAttrs data [ "final" ];

	/*
		Generate a set of options for all objects defining a template. Options can be used to determine exactly how:

		- namespace: The namespace/key list where the base of the options will be placed.
		- determineNamespace: A function taking an object. Should return a sub-namespace 
		that says where exactly the option for that object should be placed. 
		- determineOption: A function taking an object. Should return a set in the form of
		an option. This option is used as the type for all options of each object. 
		- readOnly: If true then we won't set any data. This means that any options created
		in 'determineOption' will have no effect. If false the the data is used to affect the
		objects.
		- determineData: A function taking the object and config data gotten from the option. 
		Used to modify the data from the options into such a form that the data fits
		in the objects data attribute. Optional return value is null. If that is returned then 
		the object doesn't get its data set.
		- inSzy: If true then the szy identifier will be appended to the start of the namespace
		used when creating the options. If false then not that.
		- filter: A function taking an object and returning true if that object should get an
		option. If readOnly is false then the filter can only be dependant on constant data.
	*/
	generateObjectOptions =
	{
		namespace,
		determineNamespace ? determineNamespaceDefault,
		determineOption ? determineOptionDefault,
		readOnly ? false,
		determineData ? determineDataDefault,
		inSzy ? true,
		filter ? (object: true),
	}:
	{

		extends = [ "generateObjectOptions" ];

		__functor = self:
		{
			identifier,
			config,
			data,
		}@input:
		let
			namespace' = (lib.lists.optional inSzy "${szy}") ++ namespace;

			final = szy.objects.utils.template.get { inherit config identifier; };

			/*
				All objects defining the template. 
			*/
			definitions =
			builtins.map
			(
				definition:
				{
					namespace = determineNamespace definition;
					value = definition;
				}
			) 
			(
				builtins.filter
				filter
				(
					builtins.filter
					(
						object:
							object.meta.metaData.generateObjectOptions.generateOption
					)
					(
						builtins.map
						(
							identifier:
								szy.objects.utils.definition.get { inherit config identifier; }
						) final.meta.full.definitions
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
					per object as well as the option set which decides how the options look.
				*/
				options = 
				lib.attrsets.setAttrByPath namespace'
				(
					szy.lib.attrsets.deepMergeList
					(
						builtins.map
						(
							definition:
							let
								option = determineOption definition.value;
							in
								lib.attrsets.setAttrByPath definition.namespace (lib.options.mkOption option)
						) definitions
					)
				);
			}
			{
	
				config = 
				if (readOnly)
				then {}
				else
				{

					"${szy}".meta.objects.generateObjectOptions.data = 
					builtins.filter
					(
						data:
							data.data != null
					)
					(
						builtins.map
						(
							definition:
							let
								data' = lib.attrsets.attrByPath (namespace' ++ definition.namespace) {} config;
								data = determineData definition.value data';
							in
							{
								inherit (definition.value.meta) identifier;
								inherit data;
							}
						) definitions
					);

				};

			}
		];
	};

in
	generateObjectOptions
