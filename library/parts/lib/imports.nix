{ inputs, szy, ... }:
{

	content =
	{

		toggled = 
		rec {

			makeSingleWithArgs =
			enabled:
			args:
			module':
			let
				# If there are arguments passed then the argument to a toggled import will be '{ enabled, <args> }', if there are no arguments then the argument will be 'enabled'.
				evalArguments = enabled:
				if (builtins.isAttrs args)
				then szy.lib.attrsets.deepMerge args { inherit enabled; }
				else enabled;

				importModule = builtins.tryEval (import module');

				module = if (importModule.success) then importModule.value else module';

				toggled = 
				szy.lib.toggled.makeWithArgs enabled
				{
					import = makeWithArgs enabled args;
					__functor = szy.lib.attrsets.mkForce (self: imports: self.import imports);
				};

				arguments = evalArguments toggled;
				
			in
				module arguments;

			makeSingle = enabled: module: makeSingleWithArgs enabled null module;

			makeWithArgs = 
			enabled:
			args:
			imports:
			builtins.map
			(
				module:
					makeSingleWithArgs enabled args module
			) imports;

			make = enabled: imports: makeWithArgs enabled null imports;

			__functor = self: enabled: imports: make enabled imports;

		};

	};

}
