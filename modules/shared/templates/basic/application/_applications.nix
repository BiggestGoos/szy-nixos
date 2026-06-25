{ ... }:
{ szy, lib, config, ... }:
let
	szy' = szy config;
in
{

	options."${szy}".applications = 
	let

		inheritApplication =
		application:
		application.data //
		{
			meta =
			{
				inherit (application.meta) identifier;
			};
		};

		getDefinitions = template: 
		let
			meta = szy'.objects.utils.template.getMeta { identifier = template; };
			all = builtins.map 
			(
				identifier: 
				szy.objects.utils.definition.get 
				{ 
					inherit config identifier; 
				}
			) 
			meta.full.definitions;
		in
		builtins.filter
		(
			definition:
				definition.data.enabled
		)
		all;

		getTemplates = definitions:
		let
			identifiers = lib.lists.unique (builtins.map (definition: definition.meta.template) definitions);
		in
		builtins.map 
		(
			identifier: 
			szy'.objects.utils.template.get 
			{ 
				inherit identifier;
			}
		) 
		identifiers;
	
		defaultApplications = getDefinitions "defaultApplication";
		defaultTemplates = getTemplates defaultApplications;
		applications = getDefinitions "application";
		templates = getTemplates applications;

		defaultModule.options =
		{

			default = lib.options.mkOption
			{

				type = lib.types.attrs;
				default =
				builtins.listToAttrs
				(
					builtins.map
					(
						template:
						{
							name = template.meta.name;
							value =
							let
								defaults = template.data.default;
							in
							lib.attrsets.mapAttrs
							(
								name: value:
									if (value.value == {}) then null else inheritApplication value.value
							)
							defaults;
						}
					)
					defaultTemplates
				);

			};

		};

		modules =
		builtins.map
		(
			template:
			{

				options."${template.meta.name}" = lib.options.mkOption
				{

					type = lib.types.attrs;
					default =
					let
						definitions = template.definitions;
					in
					lib.attrsets.mapAttrs
					(
						name: value:
							inheritApplication value
					)
					definitions;
				};

			}
		)
		templates;

	in
	lib.options.mkOption
	{

		type = lib.types.submoduleWith { modules = [ defaultModule ] ++ modules; };

		readOnly = true;

	};

}
