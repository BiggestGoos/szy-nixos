{ lib, szy, pkgs }:
{ final, template }:
let

	desktopEntry =
	{ config, ... }: {
	options =
	{

		final =
		let

			desktopEntry = config;
			inherit (desktopEntry) required base;

			resolveOverrides = overrides:
			lib.attrsets.filterAttrs 
			(
				name: value:
					value != null
			)
			overrides;

			baseDefaultOverrides = (final.data.desktopEntry._default or { overrides = {}; }).overrides;
			defaultOverrides = resolveOverrides baseDefaultOverrides;

			baseOverrides = desktopEntry.overrides;
			overrides = resolveOverrides baseOverrides;

			baseValues = base.values // defaultOverrides // overrides;

			values = 
			let
				fullSet =
				base: default: override: szy.utils.mergeAll [ base default override ];

				fullActions = fullSet (base.values.actions or {}) (defaultOverrides.actions or {}) (overrides.actions or {});
				fullExtra = fullSet (base.values.extraConfig or {}) (defaultOverrides.extraConfig or {}) (overrides.extraConfig or {});
			in
			baseValues //
			{
				actions = fullActions;
				extraConfig = fullExtra;
			};

			desktopEntryPackage = pkgs.makeDesktopItem (values);

			requiredKeys =
			[
				"name"
				"desktopName"
			];
			notComplete =
			lib.lists.any			
			(
				value:
					value == false
			)
			(
				builtins.map
				(
					key:
						builtins.elem key (builtins.attrNames values)
				)
				requiredKeys
			);

			result = 
			if (notComplete)
			then (lib.trivial.throwIf required "The required desktop entry for definition \"${final.meta.name}\" of template \"${final.meta.template}\" could not be created. It is missing either name or desktopName.") null
			else "${desktopEntryPackage}/share/applications/${values.name}.desktop";

			strType = if (required) then lib.types.str else lib.types.nullOr lib.types.str;

		in
		{		

			path = lib.options.mkOption
			{
				type = strType;
				readOnly = true;
				default = result;
			};

			id = lib.options.mkOption
			{
				type = strType;
				readOnly = true;
				default = if (notComplete) then null else "${builtins.replaceStrings [ "/" ] [ "-" ] values.name}.desktop";
			};

			values = lib.options.mkOption
			{
				type = lib.types.attrs;
				readOnly = true;
				default = values;
			};
		
		};

		base = 
		{

			path = lib.options.mkOption
			{
				type = lib.types.nullOr lib.types.str;
			};

			values = lib.options.mkOption
			{
				type = lib.types.attrs;
				readOnly = true;
				default = 
				let

					base = config.base.path;
					packagePath = "${final.data.package}";
					path = if (lib.strings.hasInfix "/" base) then base else "${packagePath}/share/applications/${base}.desktop";
					pathExists = if (base == null) then false else builtins.pathExists path;

					raw = builtins.readFile path;

					fileNameSplitter = "/share/applications/";
					splitFileName = lib.lists.drop 2 (builtins.split fileNameSplitter path);
					fileNameFromShare = lib.strings.removeSuffix ".desktop" (lib.strings.concatStrings (builtins.map (part: if (builtins.isList part) then fileNameSplitter else part) splitFileName));					
					fileNameFromLast = builtins.head (builtins.match ".*/([^/]*).desktop" path);

					fileName = if (lib.strings.hasInfix fileNameSplitter path)
					then fileNameFromShare
					else fileNameFromLast;

					nameKeys =
					{
						Type = "type";
						Name = "desktopName";
						GenericName = "genericName";
						NoDisplay = "noDisplay";
						Comment = "comment";
						Icon = "icon";
						OnlyShowIn = "onlyShowIn";
						NotShowIn = "notShowIn"; 
						DBusActivatable = "dbusActivatable";
						TryExec = "tryExec";
						Exec = "exec";
						Path = "path";
						Terminal = "terminal";
						MimeType = "mimeTypes";
						Categories = "categories";
						Implements = "implements";
						Keywords = "keywords";
						StartupNotify = "startupNotify";
						StartupWMClass = "startupWMClass";
						URL = "url";
						PrefersNonDefaultGPU = "prefersNonDefaultGPU";
					};
					names = builtins.attrNames nameKeys;

					keyIsList =
					[
						"onlyShowIn"
						"notShowIn"
						"mimeTypes"
						"categories"
						"implements"
						"keywords"
					];

					keyIsBool =
					[
						"noDisplay"
						"dbusActivatable"
						"terminal"
						"startupNotify"
						"prefersNonDefaultGPU"
					];

					splitRaw = builtins.split "\n[[]Desktop Action ([^\n]*)[]][ ]*\n" raw;

					splitRows = 
					list: 
					builtins.filter 
					(
						value: 
							value != [] && 
							value != "" && 
							!(lib.strings.hasPrefix "#" value) &&
							!(lib.strings.hasPrefix "[" value)
					) 
					(
						builtins.split "\n" list
					);

					mainRows = splitRows (builtins.head splitRaw);

					actionNames = 
					builtins.filter
					(
						value:
							value != null
					)
					(
						builtins.map 
						(
							row: 
								if !(builtins.isList row)
								then null
								else builtins.head row
						) 
						splitRaw
					);

					splitAction = action: data: builtins.filter (value: value != []) (builtins.split "\n[[]Desktop Action ${action}[]][ ]*\n" data);

					rawActionSplits = 
					lib.lists.drop (if ((builtins.length actionNames) == 1) then 0 else 1)
					(lib.lists.foldl
					(
						list: action: 
						let
							isFirst = action == (builtins.head actionNames);
							isLast = action == (lib.lists.last actionNames);

							data = 
							if (isFirst)
							then raw
							else lib.lists.last (lib.lists.last list);

							split = splitAction action data;
						in
							list ++ [ split ]
					) 
					[]
					actionNames);

					actionsRows =
					let
						end = (builtins.length actionNames) - 1;
					in
					builtins.listToAttrs
					(
						builtins.map
						(
							i:
							let
								action = builtins.elemAt actionNames i;
								value = 
								if (i != end)
								then builtins.head (builtins.elemAt rawActionSplits i)
								else lib.lists.last (lib.lists.last rawActionSplits);
							in
							{
								name = action;
								value = splitRows value;
							}
						)
						(lib.lists.range 0 end)
					);

					parseRows = 
					isAction: rows:
					let
						keyValue = 
						builtins.listToAttrs
						(
							builtins.map
							(
								row:
								let
									name = builtins.head (builtins.match "([^=]*)=.*" row);
									value = builtins.head (builtins.match "[^=]*=(.*)" row);
								in
								{
									inherit name value;
								}
							)
							rows
						);

						removeExtra =
						lib.attrsets.filterAttrs 
						(
							name: value:
								(builtins.elem name names)
						)
						keyValue;

						extra =
						lib.attrsets.filterAttrs 
						(
							name: value:
								!(builtins.elem name names)
						)
						keyValue;

						mappedKeys =
						lib.attrsets.mapAttrs'
						(
							name: value:
							let
								mappedName = nameKeys."${name}";
							in
							{
								name = if (mappedName == "desktopName" && isAction) then "name" else mappedName; # In actions it's called name and not desktopName
								value =
								let
									# String values (which all lists are) can only contain ASCII values (according to spec). We use this to escape "\;".
									temp = builtins.replaceStrings [ ''\;'' ] [ "¤" ] value;
									split = builtins.filter (value: value != "") (lib.strings.splitString ";" temp);
									result = builtins.map (value: builtins.replaceStrings [ "¤" ] [ ''\;'' ] value) split;
								in
								if (builtins.elem mappedName keyIsList)
								then result
								else if (builtins.elem mappedName keyIsBool)
								then builtins.fromJSON value
								else value;
							}
						)
						removeExtra;
						
						result = 
						if (isAction)
						then mappedKeys
						else mappedKeys //
						{
							name = fileName;
							extraConfig = extra;
						};

					in
						result;

					main = parseRows false mainRows;
					actions =
					lib.attrsets.mapAttrs
					(
						name: value:
							parseRows true value
					)
					actionsRows;

					result =
					main //
					{
						inherit actions;
					};

				in
					if (pathExists) then result else {};
			};

		};

		overrides =
		let
			string = lib.types.str;
			list = lib.types.listOf lib.types.str;
			bool = lib.types.bool;
			keys = 
			{
				name = string;
				type = string;
				desktopName = string;
				genericName = string;
				noDisplay = bool;
				comment = string;
				icon = string;
				onlyShowIn = list;
				notShowIn = list; 
				dbusActivatable = bool;
				tryExec = string;
				exec = string;
				path = string;
				terminal = bool;
				mimeTypes = list;
				categories = list;
				implements = list;
				keywords = list;
				startupNotify = bool;
				startupWMClass = string;
				url = string;
				prefersNonDefaultGPU = bool;
			};
		in
		(
			lib.attrsets.mapAttrs
			(
				name: value:
				lib.options.mkOption
				{
					type = lib.types.nullOr value;
					default = null;
				}
			)
			keys
		) //
		{

			extraConfig = lib.options.mkOption
			{
				type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
				default = null;
			};

			actions = lib.options.mkOption
			{
				type = lib.types.nullOr (lib.types.attrsOf (lib.types.submoduleWith { modules = [ { options =
				{

					name = lib.options.mkOption
					{
						type = lib.types.nullOr lib.types.str;
						default = null;
					};

					exec = lib.options.mkOption
					{
						type = lib.types.nullOr lib.types.str;
						default = null;
					};

					icon = lib.options.mkOption
					{
						type = lib.types.nullOr lib.types.str;
						default = null;
					};

				}; } ]; }));
				default = null;
			};

		};

		required = lib.options.mkOption
		{
			type = lib.types.bool;
			default = false;
		};

	}; };

in
{

	desktopEntry = lib.options.mkOption
	{

		type = lib.types.nullOr (lib.types.attrsOf (lib.types.submoduleWith { modules = [ desktopEntry ]; }));

	};

}
