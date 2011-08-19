class TowerGameplayEventsWriter extends GameplayEventsWriter;

`include(Tower\Classes\TowerStats.uci);

final function LogGamePositionStringEvent(int EventId, const out vector Position, string Value)
{
	local GenericParamListStatEntry Entry;
	Entry = GetGenericParamListEntry();
	Entry.AddVector('Position', Position);
	Entry.AddString('Value', Value);
	Entry.CommitToDisk();
}

DefaultProperties
{
	//SupportedEvents.Add((EventID=GAMEEVENT_PLAYER_LOCATION_POLL,EventName="Player Locations",StatGroup=(Group=GSG_Player,Level=10),EventDataType=`GET_PlayerLocationPoll))
	SupportedEvents.Add((EventID=GAMEEVENT_PLAYER_SPAWNED_BLOCK,EventName="Player Spawned Block",StatGroup=(Group=GSG_GameSpecific,Level=9),EventDataType=`GET_GameString))
}