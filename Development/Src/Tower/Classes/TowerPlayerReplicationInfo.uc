class TowerPlayerReplicationInfo extends PlayerReplicationInfo
	config(Tower);

enum InformClient
{
	IC_ModuleAdded,
	IC_ModuleRemoved,
	IC_ModuleNewTarget,
	IC_ModuleFire
};

struct ModOption
{
	var String ModName;
	var bool bEnabled;
	var bool bRunForServer;
};

struct ModuleInfo
{
	var Vector GridLocation;
	var int ModIndex, ModPlaceableIndex;
	var TowerBlock Parent;
	var int ID;
};

var Tower Tower;
/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var protectedwrite globalconfig LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it.
Setting this to 1 means no bloom assuming HighlightColor has no colors over 1.*/
var protectedwrite globalconfig byte HighlightFactor;

/** If TRUE, ModLoaded() in TowerModInfo contains an array of mod names, if FALSE, it contains an
empty array.*/
var protected globalconfig bool bShareModNamesWithMods;
var protected globalconfig bool bDebugMods;

/** Holds a reference to all TowerModules, since they can't be replicated.
Despite being independent, everyone's Modules array should always be synchronized. */
var private array<TowerModule> Modules;

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

simulated function TowerModuleReplicationInfo GetTMRI()
{
	return TowerGameReplicationInfo(WorldInfo.GRI).ModuleReplicationInfo;
}

reliable server function ServerAddModule(TowerModule Module)
{
	local InfoPacket Packet;
	Module.ID = GetTMRI().NextModuleID;
	GetTMRI().Modules.AddItem(Module);
	GetTMRI().NextModuleID++;
	Packet.Count = GetTMRI().Modules.Length;
	Packet.Checksum += Module.ID;
	GetTMRI().Packet = Packet;
}

function ServerRemoveModule(int ModuleID)
{
	local int Index;
	local InfoPacket Packet;
	local TowerModule Module;
	`log("Iterating through"@GetTMRI().Modules.Length@"modules.");
	foreach GetTMRI().Modules(Module, Index)
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
		Packet.Checksum = GetTMRI().Packet.Checksum - GetTMRI().Modules[Index].ID;
		GetTMRI().Modules.Remove(Index, 1);
		Packet.Count = GetTMRI().Modules.Length;
		GetTMRI().Packet = Packet;
	}
}

function InformClientOf(InformClient Type, optional int InInt, optional Actor InActor, optional ModuleInfo InModuleInfo)
{
	local PlayerReplicationInfo PRI;
	local TowerPlayerReplicationInfo TPRI;
	foreach WorldInfo.GRI.PRIArray(PRI)
	{
		TPRI = TowerPlayerReplicationInfo(PRI);
		switch(Type)
		{
		case IC_ModuleAdded:
			//TPRI.ClientModuleAdded();
			break;
		}
	}
}

/** Deprecated. */
reliable server function QueryModuleInfo(int ModuleID)
{
	local TowerModule Module;
	local ModuleInfo Info;
	local int ModIndex, ModPlaceableIndex;
	`log("Received query for module:"@ModuleID);
	foreach GetTMRI().Modules(Module)
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

/** Deprecated. */
reliable client function ReceiveModuleInfo(ModuleInfo Info)
{
	local TowerModule Module;
	`log("Received module info for module:"@Info.ID@Info.Parent);
	if(GetTMRI().ModuleExist(Info.ID))
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
		
		GetTMRI().AddModule(Module);
	}
}

/** Under normal circumstances removing items from the Modules array keeps the size the same but replaces the element with None.
This forces everyone to go through the array and remove any None elements. */
reliable client function ForceCompactArrays();

reliable client function ClientModuleAdded(ModuleInfo Info);

reliable client function ClientModuleRemoved(int Index);

unreliable client function ClientModuleNewTarget(Actor Target);

unreliable client function ClientModuleFire();

DefaultProperties
{
	bSkipActorPropertyReplication=False
}