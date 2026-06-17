{ options, lib, utils, variants }:
{

	mkThemed = { path, config, option, themes, modifiers ? [], enabled ? true, defaultTheme, defaultModifiers ? [], configuration ? {}, additionalOptions ? {} }:
	let
		keyNames = [ options ] ++ option;
	in
	variants.mkVarying {
		inherit path config option;
		configuration = lib.mkIf (enabled) configuration;
		variants = themes;
		default = if (defaultTheme == null) then null else [ defaultTheme ];
		additionalOptions = utils.mergeAll [ additionalOptions (lib.attrsets.setAttrByPath keyNames ({

			themes.enabled = lib.mkOption {
				type = lib.types.enum themes;
				default = 
				let
					globalEnabled = config."${options}".themes.enabled;
				in
					(if ((globalEnabled == null) || !(builtins.elem globalEnabled themes)) then
						defaultTheme
					else
						globalEnabled);
			};

			themes.modifiers.enabled = lib.mkOption {
				type = lib.types.listOf (lib.types.enum modifiers);
				default = 
				let
					globalModifiers = config."${options}".themes.modifiers;
					intersected = lib.lists.intersectLists globalModifiers defaultModifiers;
				in
					(if (globalModifiers == null || (builtins.length intersected) == 0) then
						defaultModifiers
					else
						intersected);
			};

			variants.enabled = lib.mkOption {
				type = lib.types.nullOr (lib.types.listOf (lib.types.enum themes));
				readOnly = true;
				default = if (enabled == false) then null else [ (lib.attrsets.getAttrFromPath (keyNames ++ [ "themes" "enabled" ]) config) ];
			};

		})) ];
		additionalData = 
		let
			enabledModifiers = (lib.attrsets.getAttrFromPath (keyNames ++ [ "themes" "modifiers" "enabled" ]) config);
		in
		{
			modifiers = {

				enabled = enabledModifiers;
				has = modifier: builtins.elem (assert (builtins.elem modifier modifiers); modifier) enabledModifiers;

			};
		};
	};

}
