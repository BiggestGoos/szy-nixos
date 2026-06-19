{ lib, szy, ... }:
{

	content =
	rec {

		makeWithArgs = 
		enabled:
		args:
		(
			szy.lib.attrsets.deepMerge
			rec {
				is = enabled;
				enableIf = lib.mkIf enabled;
				__functor = self: value: enableIf value;
			}
			args
		);

		make = enabled: makeWithArgs enabled {};

		__functor = self: enabled: make enabled;

	};

}
