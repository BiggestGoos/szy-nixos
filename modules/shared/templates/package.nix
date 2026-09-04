{ szy, config, lib, pkgs, ... }:
(szy config).objects.make.template
{

	name = "package";

	variable' =
	{ variable, ... }:
	{
		# The input package. Templates that want to modify the package should probably read from this.
		input = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = null;
		};

		/*
			A list of override actions that will be performed on the input package when creating the final package.
		*/
		overrides = lib.options.mkOption
		{
			type = 
			let
				module.options =
				{
					name = lib.options.mkOption
					{
						type = lib.types.str;
						default = "overrideAttrs";
					};

					value = lib.options.mkOption
					{
						type = lib.types.anything;
					};
				};
			in
			lib.types.listOf (lib.types.submoduleWith { modules = [ module ]; });
			default = [];
		};
	};

	variable =
	{ meta, ... }:
	let
		name = lib.lists.last meta.identifier;
	in
	{
		# Attempts to find a package based on the object's name
		input =
		let
			package = pkgs.${name} or null;
		in
		lib.mkIf (package != null) (lib.mkDefault package);
	};

	constant' =
	{ variable, ... }:
	let

		inherit (variable) overrides input;

		/*
			The final package is the input package overriden with the list of overrides.

			If no overrides are supplied then the final package is equal to the input package.
		*/
		package = 
		if input == null
		then null
		else
		let
			resolve = package: overrides:
			let
				curOverride = builtins.head overrides;
				newOverrides = lib.lists.drop 1 overrides;
				newPackage = package."${curOverride.name}" curOverride.value;
			in
			if overrides == []
			then package
			else resolve newPackage newOverrides;
		in
			resolve input overrides;
	in
	{

		final = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			readOnly = true;
			default = package;
		};

	};

}
