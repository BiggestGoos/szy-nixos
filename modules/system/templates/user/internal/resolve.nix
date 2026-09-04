{ users, types, ... }:
{ enabled, variable, ... }:
{ szy, config, lib, ... }:
{

	config =
	{

		users = 
		let
			
			allGroups =
			lib.lists.unique
			(
				builtins.concatLists
				(
					builtins.map
					(
						user:
						let
							primary = 
							if (user.variable.primaryGroup == null)
							then []
							else [ user.variable.primaryGroup ];
						in
							primary ++ user.variable.groups
					) users
				)
			);
		in
		enabled
		{

			defaultUserShell =
			let
				shell = ((szy config).objects.utils.get { identifier = [ "template" "programs" "shell" ]; }).constant.default.any;
				package =
				if shell == null
				then null
				else shell.constant.program.package.final;
			in
				lib.mkIf (package != null) package;

			# Here we append all the users to the real system users
			users =
			builtins.listToAttrs
			(
				builtins.map
				(
					user:
					let
						typesSettings = 
						builtins.map	
						(
							type:
								config."${szy}".users.types."${type}".settings
						) user.variable.types;
					in
					{
						name = user.constant.username;
						value = 
						szy.lib.attrsets.deepMergeList
						(
							typesSettings ++
							[
								{ # This will be the real values in users.users.<user>

									home = szy.lib.attrsets.mkForce (lib.mkForce user.variable.homeDirectory);

									isNormalUser = szy.lib.attrsets.mkDefault true; # By default we set users to be normal, this can be overriden.
									isSystemUser = szy.lib.attrsets.mkDefault false;

									extraGroups = user.variable.groups;
									group = lib.mkIf (user.variable.primaryGroup != null) user.variable.primaryGroup;

									shell = szy.lib.attrsets.mkDefault (lib.mkIf (user.variable.shell != null) user.variable.shell);

								}
								user.variable.settings
							]
						);
					}
				) users
			);

			# We make sure that all referenced groups *exist*, they are easily overriden to hold gids and such.
			groups =
			builtins.listToAttrs
			(
				builtins.map
				(
					group:
					{
						name = group;
						value = lib.mkDefault {};
					}
				) allGroups
			);

		};

	};

}
