{ szy, lib, config, systemConfig, ... }:
let

	inherit (config."${szy}") packages;

in
{

	options."${szy}".packages = lib.options.mkOption
	{
		type = lib.types.listOf lib.types.package;
		default = [];
	};

	config =
	if (systemConfig)
	then
	{

		environment.systemPackages = packages;

	}
	else
	{

		home.packages = packages;

	};

}
