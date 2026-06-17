{ szy, lib, config, systemConfig, ... }:
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
	if (systemConfig)
	then
	{

		environment.sessionVariables = setDefault variables;

	}
	else
	{

		home.sessionVariables = setDefault variables;
		systemd.user.sessionVariables = setDefault variables;

	};

}
