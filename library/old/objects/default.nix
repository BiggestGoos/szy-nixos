{ identifier, lib, utils, meta, importLib, ... }@gInputs:
let

	internal =
	rec {

		resolveSet = argument: data:
		if ((builtins.isFunction data) || (builtins.hasAttr "__functor" data))
		then (data argument)
		else data;

		# Not used but still cool, might consider in future
		/*# https://discourse.nixos.org/t/problems-with-types-oneof-and-submodules/15197/5
		typecheckSubmoduleByTryEval = submodule: 
		let
			check = x: 
			(
				builtins.tryEval 
				(
					(
						lib.modules.evalModules 
						{
							modules = submodule.getSubModules ++ [ x ];
						}
					).config
				)
			).success;
		in 
			lib.types.addCheck submodule check;

		mkNestedModule = submodule:
		let

			submoduleType = lib.types.submoduleWith { modules = [ submodule ]; };

			treeType = 
			let
				leafOrBranch = lib.types.oneOf 
				[
       				(typecheckSubmoduleByTryEval submoduleType)
					(lib.types.attrsOf leafOrBranch)
       			];
       		in 
				leafOrBranch;

		in
			treeType;*/

	};

	helperInputs = gInputs // { inherit helper; };

	inputs = helperInputs // { inherit qualifiers internal; };

	declare = import ./declare.nix inputs;
	define = import ./define.nix inputs;
	helper = import ./helper.nix gInputs;
	qualifiers = import ./qualifiers helperInputs;

in
{

	inherit (declare) declare;
	inherit (define) define;
	inherit helper internal qualifiers;

}
