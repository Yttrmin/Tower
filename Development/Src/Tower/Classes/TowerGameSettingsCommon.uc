class TowerGameSettingsCommon extends UDKGameSettingsCommon;

/** The UID of the steam game server, for use with steam sockets */
var databinding string SteamServerId;

DefaultProperties
{
	NumPublicConnections=4;
	NumOpenPublicConnections=4;
}