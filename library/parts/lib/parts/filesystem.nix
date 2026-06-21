{ lib, szy, ... }:
{

	content =
	{
		
		/*
			Creates an attrset that represents the file structure of the given directory. All files including non .nix ones are included.
			All values have the attribute '__toString' such that if you convert the attribute to a string the path it represents will be returned.
			All non-directory attributes also have an attribute called 'path' holding the path.
		*/
		attrsetFromDirectory = directory:
		let
			base = builtins.toString directory;

			filesRaw = lib.filesystem.listFilesRecursive directory;

			directories' =
			lib.lists.unique
			(
				builtins.map
				(
					path:
						builtins.dirOf (builtins.toString path)
				) filesRaw
			);

			directories =
			let

				allSubdirectories = directory:
				let
					subdir = builtins.dirOf directory;
					subdirs = allSubdirectories subdir;
				in
				if (directory == base)
				then [ directory ]
				else subdirs ++ [ directory ];

			in
			lib.lists.unique
			(
				lib.lists.flatten
				(
					builtins.map
					(
						path:
							allSubdirectories path
					) directories'
				)
			);

			attrsets =
			builtins.map
			(
				path:
				let
					relative = lib.strings.removePrefix base path;
					keys = lib.lists.drop 1 (lib.strings.splitString "/" relative);

					files' = builtins.readDir path;

					files =
					lib.attrsets.mapAttrs
					(
						name: value:
						szy.lib.attrsets.mkDefault # Make sure that any other directories override these values
						{
							path = path + "/${name}";
							__toString = self: self.path;
						}
					) files';

					value =
					{
						__toString = self: path; # If there ever is a file/directory named __toString then this would conflict, well
					} // files;
				in
					lib.attrsets.setAttrByPath keys value
			) directories;

			merged = szy.lib.attrsets.deepMergeList attrsets;

		in
			merged;

	};

}
