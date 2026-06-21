{ arguments, szy, lib, inputs, ... }:
let

	mkValue = namespace: name: prettyName: typeFunc: typeName:
	{
		inherit name;
		requiredArguments = [ (namespace ++ [ name ]) ];
		content = 
		let
			value = lib.attrsets.getAttrFromPath (namespace ++ [ name ]) arguments;
		in
			(lib.trivial.throwIfNot (typeFunc value) "${prettyName} must be a ${typeName}!") value;
	};

in
{

	content =
	{

		identifier = 
		let
			base = "szy";
			hasHostname = lib.attrsets.hasAttrByPath [ "host" "name" ] szy.data;
		in
		if (hasHostname)
		then "${base}-${szy.data.host.name}"
		else base;

	} // 
	(
		if (arguments ? root) # For some reason it didn't work with my 'requiredArguments' system, this works though so it's fine I guess. Maybe bug in implementation.
		then 
		{
			root = szy.lib.filesystem.attrsetFromDirectory (builtins.unsafeDiscardStringContext arguments.root); # Should be safe since it's literally directly the root of the config
		}
		else {}
	);

	imports =
	[
		{
			requiredArguments = [ [ "flake" "root" ] ];

			name = "flake";

			content.root = arguments.flake.root;
		}
		{
			name = "host";
			imports =
			let
				mkHostValue = mkValue [ "host" ];
			in
			[
				(mkHostValue "name" "Hostname" builtins.isString "string")
				(mkHostValue "path" "Path" builtins.isPath "path")
				(mkHostValue "system" "System" builtins.isString "string")
				(mkHostValue "stateVersion" "NixOS state version" builtins.isString "string")
			];
		}
		{
			name = "configType";
			requiredArguments = [ [ "configType" ] ];
			content = 
			let
				allowedTypes = [ "system" "user" ];
				inherit (arguments) configType;
			in
				(lib.trivial.throwIfNot (builtins.elem configType allowedTypes) "Config type must be one of: ${builtins.toJSON allowedTypes}. Current value: { ${configType} }") configType;
		}
	];

}
