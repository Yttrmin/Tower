class TowerPlayerReplicationInfo extends PlayerReplicationInfo
	config(Tower);

struct ModOption
{
	var String ModName;
	var bool bEnabled;
	var bool bRunForServer;
};

var Tower Tower;
/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var config LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it.
Setting this to 1 means no bloom assuming HighlightColor has no colors over 1.*/
var config byte HighlightFactor;

/** If TRUE, ModLoaded() in TowerModInfo contains an array of mod names, if FALSE, it contains an
empty array.*/
var protected globalconfig bool bShareModNamesWithMods;
var protected globalconfig bool bDebugMods;

replication
{
	if(bNetDirty)
		Tower, HighlightColor;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetHighlightColor(HighlightColor);
	RequestUpdatedTime();
}

reliable server function SetHighlightColor(LinearColor NewColor)
{
	NewColor.R *= HighlightFactor;
	NewColor.G *= HighlightFactor;
	NewColor.B *= HighlightFactor;
	HighlightColor = NewColor;
}

reliable server function RequestUpdatedTime()
{
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = 
		TowerGame(WorldInfo.Game).GetRemainingTime();
	`log("UPDATED TIME! NEW VALUE:"@TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime);
}

simulated function TowerPlayerController GetPlayerController()
{
	//@TODO - Doesn't handle split screen.
	local TowerPlayerController PC;
	foreach LocalPlayerControllers(class'TowerPlayerController',PC)
	{
		return PC;
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TowerModuleReplicationInfo-related functions.

reliable server function ServerAddModule(TowerModule Module)
{
	Module.ID = TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.NextModuleID;
	TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules.AddItem(Module);

	TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.NextModuleID++;
	TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Packet.Count = 
		TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules.Length;
	TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Packet.Checksum += Module.ID;
}

reliable server function ServerRemoveModule(int ModuleID)
{
	local int Index;
	local InfoPacket Packet;
	local TowerModule Module;
	`log("Iterating through"@TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules.Length@"modules.");
	foreach TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules(Module, Index)
	{
		`log("Found module with ID"@Module.ID);
		if(Module.ID == ModuleID)
		{
			`log("Found Module at index:"@Index);
			break;
		}
	}
	`log("Found Module"@ModuleID@"at index:"@Index@"(outside foreach)");
	if(Index != -1)
	{
		Packet.Checksum = TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Packet.Checksum - 
			TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules[Index].ID;
		TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules.Remove(Index, 1);
		TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Packet.Count = 
			TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules.Length;
		TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Packet = Packet;
	}
}

reliable server function QueryModuleInfo(int ModuleID)
{
	local TowerModule Module;
	local ModuleInfo Info;
	local int ModIndex, ModPlaceableIndex;
	`log("Received query for module:"@ModuleID);
	foreach TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.Modules(Module)
	{
		if(Module.ID == ModuleID)
		{
			Info.ID = ModuleID;
			Info.GridLocation = Module.GridLocation;
			GetPlayerController().ConvertPlaceableToIndexes(Module.ObjectArchetype, ModIndex, ModPlaceableIndex);
			Info.ModIndex = ModIndex;
			Info.ModPlaceableIndex = ModPlaceableIndex;
			Info.Parent = TowerBlock(Module.Owner);

			`log("Sent off ModuleInfo in response to query for module:"@ModuleID@Info.Parent);
			ReceiveModuleInfo(Info);
			return;
		}
	}
}

reliable client function ReceiveModuleInfo(ModuleInfo Info)
{
	local TowerModule Module;
	`log("Received module info for module:"@Info.ID@Info.Parent);
	if(TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.ModuleExist(Info.ID))
	{
		// Modify module.
	}
	else
	{
		// Spawn module
		`log("Adding module at"@Info.GridLocation);
		Module = GetPlayerController().AddLocalPlaceable(GetPlayerController().ConvertIndexesToPlaceable(Info.ModIndex, 
			Info.ModPlaceableIndex), Info.Parent, Info.GridLocation);
		Module.ID = Info.ID;
		
		TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo.AddModule(Module);
	}
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}