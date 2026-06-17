{ szy, lib, config, pkgs, systemConfig, ... }@moduleInput:
szy.objects.declare
{

	inherit config;
	
	name = "gaming";

	configuration =
	{ enabled, final }:
	if (systemConfig)
	then
	{

		boot.kernel.sysctl."vm.max_map_count" = 2147483642;

	}
	else
	let
		systemFinal = szy.objects.helper.template.get { config = moduleInput.osConfig; meta = final.meta; };
	in
	{

		warnings =
		[
			(lib.mkIf (systemFinal.data.enable == false) "Gaming is enabled in user configuration but not in system, there are certain optimizations that can only be enabled at system level.")
		];

	};

}
