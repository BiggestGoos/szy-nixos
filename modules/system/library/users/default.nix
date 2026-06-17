{ szy, lib, config, ... }:
let

	usersOptions = config."${szy}".users;
	inherit (usersOptions) available;

in
{

	options."${szy}".users = {

		available = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			readOnly = true;
			default = builtins.attrNames config."${szy}".users.declared;
		};

		default = {

			name = lib.mkOption {
				type = lib.types.enum config."${szy}".users.available;
				default = builtins.elemAt available 0;
			};

		};

		types = 
		let
			types = config."${szy}".users.types.list;
		in
		{

			list = lib.mkOption {
				type = lib.types.listOf lib.types.str;
				readOnly = true;
				default = [
					"normal"
					"system"
					"guest"
				];
			};

			groups = 
			let

				groups = builtins.listToAttrs (builtins.map (type: 
				{
					name = type;
					value = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						default = [];
					};
				}) types);

			in
				groups;
	
		};

		homeManagerPaths = lib.mkOption {
			type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ {
				options.path = lib.mkOption {
					type = lib.types.path;
				};
			} ]; });
			default = {};
		};

	};

	config = {

		users = 
		let
			systemDefault = ((config."${szy}".applications.default or {}).shell or {}).cli or null;
		in
		{
			defaultUserShell = lib.mkIf (systemDefault != null) systemDefault.package;
		};

		"${szy}".users.types.groups = {

			normal = [
				"wheel"
			];

		};

	};

}
