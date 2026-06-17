{ options, lib, utils, ... }:
{

	mkVarying = { path, config, option, variants, default ? null, configuration ? {}, additionalOptions ? {}, additionalData ? {}, allowMultipleEnabled ? true }:
	let
		keyNames = [ options ] ++ option;
	in
	{

		imports = builtins.map (variant: ((import (path + ("/" + variant)) (
		(utils.mergeAll [ ({
			name = variant;
			__toString = self: self.name;
			enabled = (if ((lib.attrsets.getAttrFromPath (keyNames ++ [ "variants" "enabled" ]) config) == null) then false else (if (allowMultipleEnabled) then (builtins.elem variant (lib.attrsets.getAttrFromPath (keyNames ++ [ "variants" "enabled" ]) config)) else (variant == (lib.attrsets.getAttrFromPath (keyNames ++ [ "variants" "enabled" ]) config))));
		}) additionalData ])
		)))) variants;

		options = (utils.mergeAll [ (lib.attrsets.setAttrByPath keyNames ({ variants = {

			available = lib.mkOption {
				type = lib.types.listOf lib.types.str;
				default = variants;
				readOnly = true;
			};

			enabled = lib.mkOption {
				type = lib.types.nullOr (if (allowMultipleEnabled) then (lib.types.listOf (lib.types.enum variants)) else (lib.types.enum variants));
				default = default;
			};

		}; })) additionalOptions ]);

		config = configuration;

	};

}
