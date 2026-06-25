{ inputs, szy, lib, ... }:
{

	content =
	{

		/*
			Propagates an argument to modules. 
			Modules can either be functions/functors or paths/strings pointing to files containing a function/functor.
		*/
		propagate =
		rec {

			# To a single module
			single = arg': module':
			let

				# Since the given might be a function/functor and might also be a path/string 
				# to import, we try to import, and if it doesn't work we assume it is a function/functor
				module = 
				if (szy.lib.functions.isCallable module') 
				then module'
				else import module';

				# If the propagated argument is an attrs then we attach an attribute called 'import' which lets the imported module
				# propagate the import to new modules easily. The import attribute is easily overridable.
				arg = 
				if (!(builtins.isAttrs arg'))
				then arg'
				else 
				szy.lib.attrsets.deepMerge
				arg'
				{
					propagate = szy.lib.attrsets.mkDefault
					rec {
						single = szy.lib.imports.propagate.single arg';
						list = szy.lib.imports.propagate.list arg';
						recursive = 
						{
							withDefault ? true,
							directory,
						}:
						szy.lib.imports.propagate.recursive { inherit withDefault directory; arg = arg'; };
						
						__functor = self: imports: list imports;
					};
				};

			in
				module arg;

			# To a list of modules, can be mixed
			list = arg: imports: builtins.map (module: single arg module) imports;

			__functor = self: arg: imports: self.list arg imports;

			# To a directory of files containing modules, will only import .nix files and stops when reacing a file named default.nix.
			# For full detail on recursive import, see szy.lib.imports.recursive.untilDefaultFile
			recursive =
			{
				arg,
				withDefault ? true,
				directory,
			}:
			list arg
			(
				szy.lib.imports.recursive.untilDefaultFile
				{
					inherit withDefault directory;
				}
			);

		};

		/*
			Toggle files to import, the files will be imported and called with an argument which tells the module if it is enabled or not.

			Example usage with NixOS imports:
			{
				imports = szy.lib.imports.toggled.list (true/false)
				[
					./foo.nix
					./bar.nix
					...
				];
			}

			In ./foo.nix:
			enabled:
			{ ... }:
			{

				x = enabled.enableIf 5; (Same as lib.mkIf (enabled.is))

			}
		*/
		toggled = 
		let

			# If there are arguments passed then the argument to a toggled import will be '{ enabled, <args> }', if there are no arguments then the argument will be 'enabled'.
			makeArgument = enabled': args:
			let
				enabled = szy.lib.toggled.make enabled';
			in
			if (builtins.isAttrs args)
			then szy.lib.attrsets.deepMerge args { inherit enabled; }
			else enabled;

		in
		rec {

			singleWithArgs = enabled: args: szy.lib.imports.propagate.single (makeArgument enabled args);

			single = enabled: module: singleWithArgs enabled null module;

			listWithArgs = enabled: args: szy.lib.imports.propagate.list (makeArgument enabled args);

			list = enabled: imports: listWithArgs enabled null imports;

			__functor = self: enabled: imports: list enabled imports;

			recursiveWithArgs =
			{
				enabled,
				args,
				withDefault ? true,
				directory,
			}:
			szy.lib.imports.propagate.recursive
			{
				inherit withDefault directory;
				arg = makeArgument enabled args;
			};

			recursive = 
			{
				enabled,
				withDefault ? true,
				directory,
			}:
			recursiveWithArgs 
			{ 
				inherit enabled withDefault directory; 
				args = null; 
			};

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

				/*
					We filter files based on a couple conditions:
					- The files ends in .nix
					- The file isn't inside a directory called /internal/
					- The file isn't in a directory starting with '_' and the filename of the file doesn't start with '_'.
	
					The first condition makes sure we only import nix files.
					The two latter conditions are to mark files as "internal" to some place, e.g. another file imports them.
				*/
				files' =
				builtins.filter
				(
					path:
					let
						str = builtins.toString path;
						conditions =
						[
							(lib.strings.hasSuffix ".nix" str)
							(!(lib.strings.hasInfix "/internal/" str))
							(!(lib.strings.hasInfix "/_" str))
						];
					in
						lib.lists.all (x: x == true) conditions
				) filesRaw;

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
					) files'
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
				) files';

			in
				files;

			__functor = self: directory: self.untilDefaultFile { inherit directory; withDefault = true; };

		};

	};

}
