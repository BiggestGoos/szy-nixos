{ arguments, szy, lib, ... }:
{

	supportedConfigType = "system";
	requiredArguments = [ [ "config" ] ];

	content =
	{

		user =
		{

			create = name: homeManaged: configuration:
			szy.objects.define
			(
				szy.lib.attrsets.deepMerge
				(
					configuration
				)
				{

					inherit (arguments) config;
					template = "user";

					extends =
					if (homeManaged)
					then [ "homeManagedUser" ]
					else [];

					inherit name;

				}
			);

		};

	};

}
