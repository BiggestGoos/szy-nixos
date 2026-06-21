{ lib, config, pkgs, szy, ... }:
let

	flattenTree = import ./flattenTree.nix;

in
{

	options."${szy}".profiles = {

		base.branches = lib.mkOption {

			type = 
			let
				template.options = {

					branches = lib.mkOption {
						type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ template ]; });	
						default = { };
					};

					configuration = lib.mkOption {
						type = lib.types.attrs;
						default = { };
					};

					resolveTo = lib.mkOption {
						type = lib.types.bool;
						default = false;
					};

				};
			in
				lib.types.attrsOf (lib.types.submoduleWith { modules = [ template ]; });

		};

		resolved = lib.mkOption {

			type = lib.types.listOf (lib.types.listOf lib.types.attrs);
			readOnly = true;

			default = (flattenTree config."${szy}".profiles.base);

		};

		available = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			readOnly = true;

			default = 
			let
				result = (builtins.map (profile: (builtins.concatStringsSep "-" (builtins.map (branch: branch.name) profile))) config."${szy}".profiles.resolved);
			in
				result;

		};

		enabled = lib.mkOption {
			type = lib.types.nullOr (lib.types.enum (config."${szy}".profiles.available));
			default = null;
		};

	};

	config = {

		specialisation = 
		let
			resolved = config."${szy}".profiles.resolved;
		in
		(builtins.listToAttrs (builtins.map (
		profile: 
		let

			name = (builtins.concatStringsSep "-" (builtins.map (branch: branch.name) profile));
			value.configuration = 
			{ 

				environment.etc."specialisation".text = name;

				"${szy}".profiles = {
					
					enabled = name;

				};
				
				imports = (builtins.map (branch: branch.configuration) profile);

			};

		in
			{
				inherit name value;
			}
		) resolved));

		# Make agnostic to bootloader.
		boot.loader.systemd-boot.extraInstallCommands = 
		let
			bootDir = config.boot.loader.efi.efiSysMountPoint;
			configPath = bootDir + "/loader/loader.conf";

			default = config."${szy}".profiles.enabled;
			bootName = if (builtins.isNull default) then "$(</etc/specialisation)" else default;
		in
		''
			if [ "${bootName}" == "" ]; then
				current_profile=""
			else
				current_profile="-specialisation-${bootName}"
			fi
			
			${pkgs.gnused}/bin/sed -i -E "s/default nixos-generation-([0-9]+).*\.conf/default nixos-generation-\1$current_profile.conf/" ${configPath}
		'';

		assertions = [
			{
				assertion = config.boot.loader.systemd-boot.enable;
				message = "At the moment systemd-boot is the only bootloader that I have set up automatic boot entry for profiles, use systemd-boot or add new bootloader!";
			}
		];


	};

}
