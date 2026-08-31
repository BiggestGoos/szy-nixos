{ szy, config, lib, pkgs, ... }:
(szy config).objects.make.template
{

	name = "package";

	variable' =
	{ variable, ... }:
	{
		input = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = null;
		};

		final = lib.options.mkOption
		{
			type = lib.types.nullOr lib.types.package;
			default = variable.input;
		};
	};

	variable =
	{ meta, ... }:
	let
		name = lib.lists.last meta.identifier;
	in
	{
		input =
		let
			package = pkgs.${name} or null;
		in
		lib.mkIf (package != null) (lib.mkDefault package);
	};

}
