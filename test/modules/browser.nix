{ szy, config, lib, pkgs, ... }:
(szy config).objects.make.template
{

	name = "browser";
	namespace = [ "programs" ];

	inherits = [ "application" "default" ];	

	template.variable.default.namespace = "programs";

	output.config =
	{ variable, ... }:
	{
		
	};

}
