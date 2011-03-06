class TowerPlayerController extends GamePlayerController
	config(Tower);

struct AddTicket
{
	var int ModIndex, ModPlaceableIndex;
	var Vector GridLocation;
	var TowerBlock Parent;
};

struct RemoveTicket
{
	var TowerBlock Parent;
	var int Index;
};

var TowerSaveSystem SaveSystem;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'TowerSaveSystem';
//	SaveSystem.TestInt = 123456;
//	SaveSystem.TransTestInt = 345678;
//	class'Engine'.static.BasicSaveObject(SaveSystem, "SaveGame.bin", true, 1);
//	class'Engine'.static.BasicLoadObject(SaveSystem, "SaveGame.bin", true, 1);
//	`log(SaveSystem.TestInt);
//	`log(SaveSystem.TransTestInt);
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	if(Role == Role_Authority && TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI == None)
	{
		TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI = TowerPlayerReplicationInfo(PlayerReplicationInfo);
	}
}

/**
Adding TowerModules:
(Note: TMRI = TowerModuleReplicationInfo, TPRI = TowerPlayerReplicationInfo, TPC = TowerPlayerController)
(Note: TPRI is used for sending client/server functions as it'd be impossible for all clients to do such with one TMRI.)

Server: 
AddPlaceable() (Called from TowerHUD. Determines whether or not Placeable needs to use tickets. In this case, yes.)
-> GenerateAddTicket() 
-> ServerSendAddTicket() (Yes, the server creates and sends AddTickets to itself. Keeps consistency.)
-> TowerGame::AddPlaceable() (Leads to TowerPlaceable::CreatePlaceable(), creates and initializes component.)
-> TPRI::ServerAddModule() (Updates TMRI's InfoPacket so that clients know to update.)

Client:
AddPlaceable() (Called from TowerHUD. Determines whether or not Placeable needs to use tickets. In this case, yes.)
-> GenerateAddTicket() 
-> ServerSendAddTicket()
... Client is done here. If the server allows it, the TMRI's InfoPacket will be updated.
XTMRI::ReplicatedEvent() (Called when InfoPacket is updated, in this case because the server accepted our addition.
X-> HandleNewInfoPacket()
X-> QueryModuleInfo() (Client finds the server has 1 more module than itself, requests info about it so it can create it.)
X... Client is done here until the server (hopefully) responds shortly.
X-> TPRI::ReceiveModuleInfo()
X-> TMRI::AddModule() (Creates identical module based on info and updates its Count and Checksum data.)


Removing TowerModules:

Server:
RemovePlaceable() (Called from TowerHUD. Determines whether or not to use RemoveModule(). In this case, yes.)
-> RemoveModule() (Creates a RemoveTicket for the next function (Modules can't be replicated).)
-> ServerSendRemoveTicket() (Yep, server sends a RemoveTicket to itself. This should probably come AFTER the rest to make sure valid.)
-> TPRI::ServerRemoveModule() (Removes Module from game and updates InfoPacket in TMRI.)
-> TPC::ServerRemovePlaceable() (Starts the chain of RemovePlaceables to actually remove Module from game.)
-> TowerGame::RemovePlaceable()

Client:
RemovePlaceable() (Called from TowerHUD. Determines whether or not to use RemoveModule(). In this case, yes.)
-> RemoveModule() (Creates a RemoveTicket for the next function (Modules can't be replicated).)
-> ServerSendRemoveTicket() 
... Client is done here. Server will update TMRI's InfoPacket if it's allowed.
TMRI::ReplicatedEvent()
-> HandleNewInfoPacket()
-> RemoveModule() (Removes the module and updates its Count and Checksum data.)


Updating TowerModules:


*/

exec function ClickDown(int ButtonID)
{
	TowerHUD(myHUD).OnMouseClick(ButtonID);
}

/** Called when mouse button is released. */
exec function ClickUp(int ButtonID)
{
	TowerHUD(myHUD).OnMouseRelease(ButtonID);
}

exec function ToggleBuildMenu(bool Toggle)
{
	`log("TOGGLEBUILDMENU:"@Toggle);
	if(Toggle)
	{
		TowerHUD(MyHUD).ExpandBuildMenu();
	}
	else
	{
		TowerHUD(MyHUD).CollapseBuildMenu();
	}
}

exec function SetHighlightColor(LinearColor NewColor)
{
	TowerPlayerReplicationInfo(PlayerReplicationInfo).SetHighlightColor(NewColor);
}

exec function RemoveAllBlocks()
{
	ServerRemoveAllBlocks();
}

//@TODO - Can't this just directly call a reliable server function in its Tower?
exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

exec function SaveGame(string FileName)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	SaveSystem.SaveGame(FileName, false, self);
}

exec function LoadGame(string FileName, bool bTowerOnly)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	SaveSystem.LoadGame(FileName, bTowerOnly, self);
}

exec function TestStaticSaveLoadGame(String FileName)
{
	class'TowerSaveSystem'.static.TestStaticSave(FileName, self);
	class'TowerSaveSystem'.static.LoadStaticSave(FileName, self);
}

exec function RequestUpdateTime()
{
	`log("REQUESTED TIME PLEASE ACTUALLY WORK PLEASE!"@WorldInfo.GRI);
	TowerPlayerReplicationInfo(PlayerReplicationInfo).RequestUpdatedTime();
}

function AddPlaceable(TowerPlaceable Placeable, TowerBlock Parent, out Vector GridLocation)
{
	local AddTicket Ticket;
	local int ModIndex, ModPlaceableIndex;
	if(!Placeable.IsReplicable())
	{
		GenerateAddTicket(Ticket, Placeable, Parent, GridLocation);
		ServerSendAddTicket(Ticket);
	}
	else
	{
		ConvertPlaceableToIndexes(Placeable, ModIndex, ModPlaceableIndex);
		ServerAddPlaceable(ModIndex, ModPlaceableIndex, Parent, GridLocation);
		//TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), Placeable, Parent, GridLocation);
	}
}

reliable server function ServerAddPlaceable(int ModIndex, int ModPlaceableIndex, TowerBlock Parent, Vector GridLocation)
{
	TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), ConvertIndexesToPlaceable(ModIndex, ModPlaceableIndex), Parent, GridLocation);
}

reliable server function ServerSendAddTicket(AddTicket Ticket)
{
	//@TODO - Make this better and less copy-paste.
	local TowerPlaceable Placeable;
	`log("Received AddTicket:"@Ticket.ModIndex@Ticket.ModPlaceableIndex@Ticket.GridLocation@Ticket.Parent);
	Placeable = TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), ConvertIndexesToPlaceable(Ticket.ModIndex, Ticket.ModPlaceableIndex),
		Ticket.Parent, Ticket.GridLocation);
	if(Placeable != None)
	{
		TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI.ServerAddModule(TowerModule(Placeable));
//		ClientHandleTicket(Ticket.TicketID, TRUE);
	}
	else
	{
//		ClientHandleTicket(Ticket.TicketID, FALSE);
	}
}

reliable server function ServerSendRemoveTicket(RemoveTicket Ticket)
{
	//@TODO - Check exists.
	ServerRemovePlaceable(GetModuleFromTicket(Ticket));
	TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI.ServerRemoveModule(Ticket.Index);
}

simulated function TowerModule AddLocalPlaceable(TowerPlaceable Placeable, TowerBlock Parent, out Vector GridLocation)
{
	local Vector SpawnLocation;
	SpawnLocation = class'TowerGame'.static.GridLocationToVector(GridLocation);
	return Placeable.AttachPlaceable(Placeable, Parent, GetTower().NodeTree, SpawnLocation, GridLocation);
}

simulated function ConvertPlaceableToIndexes(TowerPlaceable Placeable, out int ModIndex, out int ModPlaceableIndex)
{
	local TowerModInfo Mod;
	for(Mod = TowerGameReplicationInfo(WorldInfo.GRI).RootMod; Mod != None; Mod = Mod.NextMod)
	{
		ModPlaceableIndex = Mod.ModPlaceables.find(Placeable);
		if(ModPlaceableIndex != -1)
		{
			return;
		}
		ModIndex++;
	}
}

simulated function GenerateAddTicket(out AddTicket OutTicket, TowerPlaceable Placeable, TowerBlock Parent, out Vector GridLocation)
{
	OutTicket.GridLocation = GridLocation;
	OutTicket.Parent = Parent;
	
	ConvertPlaceableToIndexes(Placeable, OutTicket.ModIndex, OutTicket.ModPlaceableIndex);
//	PendingTickets.AddItem(OutTicket);
}

function TowerModule GetModuleFromTicket(out RemoveTicket Ticket)
{
	return TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI.Modules[Ticket.Index];
}

function TowerPlaceable ConvertIndexesToPlaceable(out int ModIndex, out int ModPlaceableIndex)
{
	local TowerModInfo Mod;
	Mod = TowerGameReplicationInfo(WorldInfo.GRI).RootMod;
	while(ModIndex > 0)
	{
		Mod = Mod.NextMod;
		ModIndex--;
	}
	return Mod.ModPlaceables[ModPlaceableIndex];
}

simulated function RemovePlaceable(TowerPlaceable Placeable)
{
	`log("RemovePlaceable:"@Placeable);
//	Placeable.RemoveSelf();
	//@TODO - Stupid parenting causing no collions means we have to do crap like this.
	if(Placeable.IsA('TowerBlock'))
	{
		ServerRemoveBlock(TowerBlock(Placeable));
	}
	else if(Placeable.IsA('TowerModule'))
	{
		RemoveModule(TowerModule(Placeable));
	}
	else
	{
		`log("Unknown Placeable!");
		ScriptTrace();
	}
}

simulated function RemoveModule(TowerModule Module)
{
	local RemoveTicket Ticket;
	local int Index;
	Index = GetTPRI().Modules.Find(Module);
	`log("Removing module"@Module@"at index"@Index$".");
	if(Index != -1)
	{
		Ticket.Parent = TowerBlock(Module.Owner);
		Ticket.Index = Index;
		ServerSendRemoveTicket(Ticket);
	}
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	ServerRemovePlaceable(Block);
}

reliable server function ServerRemoveModule(TowerModule Module)
{
	`log("ServerRemoveModule:"@Module);
	ServerRemovePlaceable(Module);
}

function ServerRemovePlaceable(TowerPlaceable Placeable)
{
	`log("ServerRemovePlaceable:"@Placeable);
	TowerGame(WorldInfo.Game).RemovePlaceable(GetTower(), Placeable);
}

reliable server function ServerRemoveAllBlocks()
{
	//@TODO - Make work.
	GetTower().NodeTree.RemoveNode(GetTower().NodeTree.GetRootNode());
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo);
}

//@FIXME
state Master extends Spectating
{
	ignores StartFire, StopFire;
}

DefaultProperties
{
	InputClass=class'Tower.TowerPlayerInput'
	CollisionType=COLLIDE_BlockAllButWeapons
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0078.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
		bDrawNonColliding=true
	End Object
	CollisionComponent=CollisionCylinder
}