{ szy, lib, config, ... }:
let

	inherit (config."${szy}") variables;

	setDefault = variables:
	lib.attrsets.mapAttrs
	(
		name: value:
		let
			isType = builtins.isString value.override;
			types =
			{
				default = lib.mkDefault;
				force = lib.mkForce;
			};
			isOverride = builtins.isAttrs value;
		in
		if (!isOverride)
		then lib.mkDefault value
		else if (isType)
		then (types."${value.override}" value.value)
		else (lib.mkOverride value.override value.value)
	)
	variables;

in
{

	options."${szy}".variables = lib.options.mkOption
	{
		type =
		let

			overrideModule.options =
			{
				value = lib.options.mkOption
				{
					type = lib.types.str;
				};
				override = lib.options.mkOption
				{
					type = lib.types.either lib.types.int (lib.types.enum [ "default" "force" ]);
				};
			};
			
		in
			lib.types.attrsOf (lib.types.either lib.types.str (lib.types.submoduleWith { modules = [ overrideModule ]; }));
	};

	config =
	if (szy.data.configType == "system")
	then
	{

		environment.sessionVariables = setDefault variables;

	}
	else if (szy.data.configType == "user")
	then
	{

		home.sessionVariables = setDefault variables;
		systemd.user.sessionVariables = setDefault variables;

	}
	else
	{};

}
