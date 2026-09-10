{ szy, lib, config, ... }:
let
	szy' = szy config;
in
szy'.objects.declare
{
	
	name = "default";

	metaParameters.template =
	{

		defaultTypes = lib.options.mkOption
		{
			type = lib.types.attrsOf (lib.types.functionTo lib.types.bool);
			default = {}; # { <name> = filter; }
		};

	};

	templateParameters = 
	{ final }:
	{

		default	=
		let

			types = final.meta.metaData.defaultTypes;

			definitionsBase = final.meta.definitions;
			allDefinitionsBase = final.meta.full.definitions;

			gDefinitions = builtins.filter (identifier: (szy'.objects.utils.definition.get ({ inherit identifier; })).data.enabled) definitionsBase;
			gAllDefinitions = builtins.filter (identifier: (szy'.objects.utils.definition.get ({ inherit identifier; })).data.enabled) allDefinitionsBase;

			base = 
			{ typeName, filterFunc }:
			let

				definitions = builtins.filter filterFunc (builtins.map (identifier: szy'.objects.utils.definition.get { inherit identifier; }) gDefinitions);
				allDefinitions = builtins.filter filterFunc (builtins.map (identifier: szy'.objects.utils.definition.get { inherit identifier; }) gAllDefinitions);

				defaultDefinition = if (allDefinitions == []) then null else (builtins.head allDefinitions);
				defaultIdentifier = if (defaultDefinition == null) then null else defaultDefinition.meta.identifier;

				identifier = final.data.default.identifier or final.data.default."${typeName}".identifier;

			in
			{

				identifier = lib.options.mkOption
				{

					type = 
					let

						module.options =
						{
							name = lib.options.mkOption
							{
								type = lib.types.enum (builtins.map (definition: definition.meta.identifier.name) allDefinitions);
							};

							template = lib.options.mkOption
							{
								type = lib.types.enum (builtins.map (definition: definition.meta.identifier.template) allDefinitions);
								default = 
								let
									inherit (identifier) name;

									possibleDefinitions =
									builtins.filter
									(
										definition:
											definition.meta.identifier.name == name
									) allDefinitions;

									template = 
									lib.trivial.throwIfNot
									(
										(builtins.length possibleDefinitions) == 1
									)
									"Either there is no definition with name ${name} or you also need to specify which template it defines"
									(
										(builtins.head possibleDefinitions).meta.identifier.template
									);
								in
									template;
							};
						};

					in
						lib.types.nullOr (lib.types.submoduleWith { modules = [ module ]; });

					default = defaultIdentifier;

				};

				value = lib.options.mkOption
				{
					type = lib.types.attrs;
					readOnly = true;
					default = 
					if (identifier == null) 
					then {} 
					else szy'.objects.utils.definition.get { inherit identifier; };
				};

			};

			modules = 
			if (types == {})
			then [ { options = (base { typeName = ""; filterFunc = (definition: true); }); } ]
			else [ { options = (lib.attrsets.mapAttrs 
			(
				name: value:
				base { typeName = name; filterFunc = value; }
			)
			types
			); } ];
			

		in
		lib.options.mkOption
		{
		
			type = lib.types.submoduleWith { inherit modules; };

		};

	};

}
