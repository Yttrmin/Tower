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
	var int ModuleID;
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

/**
Adding TowerModules:


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

exec function SaveGame(string FileName, bool bTowerOnly)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	SaveSystem.SaveGame(FileName, bTowerOnly, self);
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
		GetTPRI().ServerAddModule(TowerModule(Placeable));
//		ClientHandleTicket(Ticket.TicketID, TRUE);
	}
	else
	{
//		ClientHandleTicket(Ticket.TicketID, FALSE);
	}
}

reliable server function ServerSendRemoveTicket(RemoveTicket Ticket)
{
	GetTPRI().ServerRemoveModule(Ticket.ModuleID);
	ServerRemovePlaceable(GetModuleFromTicket(Ticket));
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
			`log("FOUND PLACEABLE:"@ModIndex@ModPlaceableIndex);
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
	local TowerModule Module;
	foreach Ticket.Parent.ComponentList(class'TowerModule', Module)
	{
		if(Module.ID == Ticket.ModuleID)
		{
			return Module;
		}
	}
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
	Ticket.Parent = TowerBlock(Module.Owner);
	Ticket.ModuleID = Module.ID;
	ServerSendRemoveTicket(Ticket);
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