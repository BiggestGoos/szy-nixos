{ arguments, szy, lib, ... }:
{

	supportedConfigType = "system";
	requiredArguments = [ [ "config" ] ];

	content =
	{

		user =
		{

			create = name: homeManaged: configuration:
			szy.objects.make
			(
				szy.lib.attrsets.deepMergeList
				[
					configuration
					{

						identifier = [ "users" name ];

						inherits = [ "user" ] ++
						(
							lib.lists.optional homeManaged [ "user" "homeManaged" ]
						);

					}
				]
			);

		};

	};

}
