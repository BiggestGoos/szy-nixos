{ arguments, szy, ... }:
{

	content =
	{

		identifier = 
		let
			base = "szy";
			hasHostname = szy.misc ? hostname;
		in
		if (hasHostname)
		then "${base}-${szy.misc.hostname}"
		else base;

	};

	imports =
	[
		{
			name = "hostname";
			requiredArguments = [ "hostname" ];
			content = arguments.hostname;
		}
	];

}
