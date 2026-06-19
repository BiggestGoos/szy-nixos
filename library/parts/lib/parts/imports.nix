{ inputs, szy, lib, ... }:
{

	content =
	{

		toggled = 
		rec {

			singleWithArgs =
			enabled:
			args:
			module':
			let
				# If there are arguments passed then the argument to a toggled import will be '{ enabled, <args> }', if there are no arguments then the argument will be 'enabled'.
				evalArguments = enabled:
				if (builtins.isAttrs args)
				then szy.lib.attrsets.deepMerge args { inherit enabled; }
				else enabled;

				importModule = builtins.tryEval (import module');

				module = if (importModule.success) then importModule.value else module';

				toggled = 
				szy.lib.toggled.makeWithArgs enabled
				{
					import = listWithArgs enabled args;
				};

				arguments = evalArguments toggled;
				
			in
				module arguments;

			single = enabled: module: singleWithArgs enabled null module;

			listWithArgs = 
			enabled:
			args:
			imports:
			builtins.map
			(
				module:
					singleWithArgs enabled args module
			) imports;

			list = enabled: imports: listWithArgs enabled null imports;

			__functor = self: enabled: imports: list enabled imports;

			recursiveWithArgs =
			{
				enabled,
				args,
				withDefault ? true,
				directory,
			}:
			let
				imports = szy.lib.imports.recursive.untilDefaultFile
				{
					inherit withDefault directory;
				};
			in
			builtins.map
			(
				module:
					singleWithArgs enabled args module
			) imports;

			recursive = 
			{
				enabled,
				withDefault ? true,
				directory,
			}:
			recursiveWithArgs { inherit enabled withDefault directory; args = null; };

		};

		recursive =
		{


			/*
				Imports all .nix files in the given directory up to, and if withDefault is true including, a default.nix file. 
				No files that appear at the same level or after a default.nix file is imported by this function.
			*/
			untilDefaultFile = 
			{
				withDefault ? true,
				directory,
			}:
			let

				defaultFilename = "default.nix";

				filesRaw = lib.filesystem.listFilesRecursive directory;

				# We pre-compute all paths that contain default.nix files.
				defaultDirs =
				builtins.map
				(
					path:
						(builtins.dirOf (builtins.toString path))
				)
				(
					builtins.filter
					(
						path:
						let
							isDefault = lib.strings.hasSuffix defaultFilename (builtins.toString path);
						in
							isDefault
					) filesRaw
				);

				# We filter out all files that are in a directory that a default.nix files is in. 
				# If the file being filtered is called default.nix then, if we want to include default.nix files, 
				# we check if the file is still in a directory with a default.nix file even if we remove the file's own directory.
				files = 
				builtins.filter
				(
					path:
					let
						pathStr = builtins.toString path;
						filename = lib.lists.last (builtins.split "/" pathStr);

						testIsInDirs = dirs: 
						lib.lists.any
						(
							directory:
								lib.strings.hasPrefix directory pathStr
						) dirs;

						# The file is in a directory higher or equal to a default.nix file
						inDefaultDirs = testIsInDirs defaultDirs;

						defaultDirsWithout = lib.lists.remove (builtins.dirOf pathStr) defaultDirs;
						# There is a default.nix file lower than the current file
						defaultBelow = testIsInDirs defaultDirsWithout;
					in
					if (!inDefaultDirs)
					then true
					else
					(
						if (withDefault && (filename == defaultFilename) && (!defaultBelow)) # For default.nix files to be included: withDefault == true and there are no default.nix files below 
						then true
						else false
					)
				) filesRaw;

			in
				files;

			__functor = self: directory: self.untilDefaultFile { inherit directory; withDefault = true; };

		};

	};

}
