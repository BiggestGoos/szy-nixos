{ szy, lib, ... }:
{

	nixpkgs.hostPlatform = szy.data.host.system;

	system.stateVersion = szy.data.host.stateVersion;

}
