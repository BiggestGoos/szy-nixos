{ szy, config, lib, pkgs, ... }:
(szy config).objects.make
{

	identifier = [ "programs" "steam" ];

	inherits = [ "application" ];	

	private.variable' =
	{
		bigPicture = lib.options.mkOption
		{
			type = lib.types.bool;
			default = false;
		};
	};

	constant.type = "mix";

	variable =
	{ variable, meta, ... }:
	{
		
		bigPicture = true;

		program.actions =
		{
			default.arguments =
			[
				"-tenfootui"
			];
		};

		program.package.overrides =
		[
			{
				name = "override";
				value = 
				{
					extraPkgs = pkgs': with pkgs'; 
					[
					    libXcursor
    					libXi
    					libXinerama
    					libXScrnSaver
    					libpng
    					libpulseaudio
    					libvorbis
    					stdenv.cc.cc.lib # Provides libstdc++.so.6
    					libkrb5
    					keyutils
    					# Add other libraries as needed
  					];
				};
			}
		];

	};

	output.config =
	{ constant, ... }:
	{
		programs.steam =
		{
			enable = true;
			package = constant.program.package.final;
		};
	};

}
