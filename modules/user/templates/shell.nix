{ szy, config, lib, ... }:
(szy config).objects.make.template
{

	name = "shell";
	namespace = [ "programs" ];

	inherits = [ [ "programs" "shell" "basic" ] ];

}
