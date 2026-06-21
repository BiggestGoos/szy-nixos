{ users, types, ... }:
{ enabled, final, ... }:
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
							user.data.groups
					) users
				)
			);
		in
		enabled
		{

			defaultUserShell = lib.mkIf (final.data.defaultShell != null) final.data.defaultShell;

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
								final.data.types."${type}".settings
						) user.data.types;
					in
					{
						name = user.data.username;
						value = 
						szy.lib.attrsets.deepMergeList
						(
							typesSettings ++
							[
								{ # This will be the real values in users.users.<user>

									isNormalUser = szy.lib.attrsets.mkDefault true; # By default we set users to be normal, this can be overriden.
									isSystemUser = szy.lib.attrsets.mkDefault false;

									extraGroups = user.data.groups;
									group = lib.mkIf (user.data.primaryGroup != null) user.data.primaryGroup;

									shell = szy.lib.attrsets.mkDefault (lib.mkIf (user.data.shell != null) user.data.shell);

								}
								user.data.settings
							]
						);
					}
				) users
			);

			# We make sure that all referenced groups *exist*, the are easily overriden to hold gids and such.
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
