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
	var IVector GridLocation;
	var int ModIndex, ModPlaceableIndex;
	var TowerBlock Parent;
//	var int ID;
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

/** Holds a reference to all TowerPlaceables using the ticket system, since they can't be replicated.
Despite being independent, everyone's TicketedPlaceables array should always be synchronized. */
var protectedwrite array<TowerPlaceable> TicketedPlaceables;

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

/** Called from TPC::ServerSendAddTicket() if TowerGame creates the Module.
Module is an instantiated object, not an archetype. */
function ServerAddModule(TowerModule Module)
{
	local ModuleInfo Info;
	local int ModIndex, ModPlaceableIndex;
	Info.GridLocation = Module.GridLocation;
	GetPlayerController().ConvertPlaceableToIndexes(Module.ObjectArchetype, ModIndex, ModPlaceableIndex);
	Info.ModIndex = ModIndex;
	Info.ModPlaceableIndex = ModPlaceableIndex;
	Info.Parent = TowerBlock(Module.Owner);
	
	TicketedPlaceables.AddItem(Module);
	InformClientsOf(IC_ModuleAdded,,,Info);
}


function ServerRemoveModule(int Index)
{
	TicketedPlaceables[Index] = None;
	InformClientsOf(IC_ModuleRemoved, Index);
	/*
	local int Index;
	local InfoPacket Packet;
	local TowerModule Module;
	`log("Iterating through"@GetTMRI().TicketedPlaceables.Length@"TicketedPlaceables.");
	foreach GetTMRI().TicketedPlaceables(Module, Index)
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
		Packet.Checksum = GetTMRI().Packet.Checksum - GetTMRI().TicketedPlaceables[Index].ID;
		GetTMRI().TicketedPlaceables.Remove(Index, 1);
		Packet.Count = GetTMRI().TicketedPlaceables.Length;
		GetTMRI().Packet = Packet;
	}
	*/
}

function InformClientsOf(InformClient Type, optional int InInt, optional Actor InActor, optional out ModuleInfo InModuleInfo)
{
	local PlayerReplicationInfo PRI;
	local TowerPlayerReplicationInfo TPRI;
	foreach WorldInfo.GRI.PRIArray(PRI)
	{
		if(!PRI.IsOwnedBy(GetPlayerController()))
		{
			TPRI = TowerPlayerReplicationInfo(PRI);
			switch(Type)
			{
			case IC_ModuleAdded:
				TPRI.ClientModuleAdded(InModuleInfo);
				break;
			case IC_ModuleRemoved:
				TPRI.ClientModuleRemoved(InInt);
				break;
			}
		}
	}
}

/** Under normal circumstances removing items from the TicketedPlaceables array keeps the size the same but replaces the element with None.
This forces everyone to go through the array and remove any None elements. */
reliable client function ForceCompactArrays();

reliable client function ClientModuleAdded(ModuleInfo Info)
{
	`log("Server says Module added!");
	TicketedPlaceables.AddItem(GetPlayerController().AddLocalPlaceable(GetPlayerController().ConvertIndexesToPlaceable(Info.ModIndex,
		Info.ModPlaceableIndex), Info.Parent, Info.GridLocation));
//	TicketedPlaceables[TicketedPlaceables.Length-1].SetOwner(Info.Parent);
}

reliable client function ClientModuleRemoved(int Index)
{
	`log("Server says Module removed!");
	TicketedPlaceables[Index].RemovePlaceable(TicketedPlaceables[Index], GetPlayerController().GetTower().NodeTree);
	TicketedPlaceables[Index] = None;
}

unreliable client function ClientModuleNewTarget(Actor Target);

unreliable client function ClientModuleFire();

DefaultProperties
{
	bSkipActorPropertyReplication=False
}