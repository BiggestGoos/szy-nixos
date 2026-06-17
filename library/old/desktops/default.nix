{ config, lib, options, utils }:
rec {
	
	mkDesktop = { name, enabled ? [], imports ? [], configuration ? { ... }: {}, globalImports ? [], globalConfiguration ? {}, additionalOptions ? {}, styles ? [] }:
	let
		
		resolvedStyles = [ { names = []; variants = []; } ] ++ styles;

	in
	{

		imports = [ globalConfiguration ] ++ globalImports;
		
		options = (utils.mergeAll [ (utils.mergeAll [ {

			"${options}".desktops.desktops = (builtins.listToAttrs (builtins.map (style: 
			let
				resolvedNames = [ name ] ++ style.names;
				resolvedName = lib.strings.concatStringsSep "+" (resolvedNames);
				isEnabled = (builtins.elem style.names config."${options}".desktops.desktops."${name}".styles.enabled);
			in
			{

				name = resolvedName;
				
				value = {

					names = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						readOnly = true;
						default = [ name ] ++ style.names;
					};

					isEnabled = lib.mkOption {
						type = lib.types.bool;
						readOnly = true;
						default = if (isEnabled == null) then false else isEnabled;
					};

					enabled = lib.mkOption {
						type = lib.types.listOf (lib.types.enum config."${options}".desktops.available);
						readOnly = true;
						default = [ resolvedName ] ++ enabled;
					};

					imports = lib.mkOption {
						type = lib.types.listOf lib.types.path;
						readOnly = true;
						default = imports;
					};

					configuration = lib.mkOption {
						type = lib.types.attrs;
						readOnly = true;
						default = { __functor = (self: ({ desktop, ... }@args: (utils.mergeAll [ (configuration { inherit desktop args; }) 
						(lib.optionalAttrs ((builtins.length style.variants) != 0) { 
							
							"${options}".desktops.desktops."${name}".variants.enabled = style.variants;

						}) ]))); };
					};

				};

			}) resolvedStyles));
		} additionalOptions ]) ({ 

			"${options}".desktops.desktops."${name}".styles.enabled = lib.mkOption {
				type = lib.types.listOf (lib.types.enum (builtins.map (style: style.names) resolvedStyles));
				default = [ [] ];
			};

		}) ]);

	};

}
