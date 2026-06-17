{ inputs }:
let
	flake = inputs.self;
	root = "${flake}";

	inherit (inputs) nixpkgs;
	inherit (nixpkgs) lib;

	self = 
	rec {

		inherit inputs;

		flake = import ./flake { inherit self lib; };

		__functor = 
		self:
		{ hostname, rawRoot }:
		let

			szy = 
			let

				inherit (self.inputs.self.nixosConfigurations."${hostname}") config _module;

				importLib = import ./import { inherit root lib; };

				parts = rec {

					meta = import ./meta { inherit lib; };

					utils = import ./utils { inherit root rawRoot hostname lib; };
					desktops = import ./desktops { inherit config lib utils; options = identifier; };
					profiles = import ./profiles;

					objects = import ./objects { inherit identifier config lib utils meta importLib; };
					programs = import ./objects/programs { inherit config lib utils; options = identifier; };

					users = import ./users { inherit config lib nixpkgs szy; options = identifier; };
					variants = import ./variants { inherit lib utils; options = identifier; };
					themes = import ./themes { inherit lib utils variants; options = identifier; };

				};

				identifier = "szy-" + parts.utils.hostname;

			in
			parts // {

				inherit config;

				import = importLib;

				__toString = self: identifier;

			};

		in
			szy;

	};

in
	self
