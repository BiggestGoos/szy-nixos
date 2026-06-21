{ szy, lib, config, ... }:
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
	if (szy.data.configType == "system")
	then
	{

		environment.systemPackages = packages;

	}
	else if (szy.data.configType == "user")
	then
	{

		home.packages = packages;

	}
	else
	{};

}
