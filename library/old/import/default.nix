{ root, lib }:
let

	_propogate = object: imports: builtins.map (module: if (builtins.isFunction (import module)) then ((import module) ({  inherit (object) value; import = _propogate object; __functor = self: _propogate object; })) else (import module)) imports;

	propogate = object: imports: _propogate { value = object; } imports;

	mkToggleable = 
	enabled: imports: 
	builtins.map 
		(module:
		let
			importFunc = mkToggleable enabled;
			evaluatedModule = if (builtins.isFunction module) then module else import module;
		in
		(evaluatedModule) 
		rec { 
			inherit enabled;
			is = enabled;
			import = importFunc;
			enableIf = lib.mkIf enabled;
			__functor = self: value: 
			let
				function = if (builtins.isList value) then importFunc else enableIf;
			in
				function value; 
		}) 
	imports;

in
rec {

	internal.shared = rec {

		path = root + "/szy/modules/internal/shared";
		from = file: path + "/${file}";

	};

	modules = rec {

		path = root + "/szy/modules";
		from = file: path + "/${file}";

		users.user = rec {

			path = root + "/szy/modules/users/user";

			desktops = rec {
				
				path = root + "/szy/modules/users/user/desktops";

			};

		};

		system = path + "/system";
		user = path + "/user";
		shared = path + "/shared";

	};

	inherit propogate;
	
	inherit mkToggleable;

}
