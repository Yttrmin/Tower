class TowerPlayerController extends GamePlayerController
	config(Tower);

struct AddTicket
{
	var int TicketID;
	var int ModIndex, ModPlaceableIndex;
	var Vector GridLocation;
	var TowerBlock Parent;
};

var int NextTicketID;
var array<AddTicket> PendingTickets;
var TowerSaveSystem SaveSystem;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'TowerSaveSystem';
	`log("TPC PBP");
//	SaveSystem.TestInt = 123456;
//	SaveSystem.TransTestInt = 345678;
//	class'Engine'.static.BasicSaveObject(SaveSystem, "SaveGame.bin", true, 1);
//	class'Engine'.static.BasicLoadObject(SaveSystem, "SaveGame.bin", true, 1);
//	`log(SaveSystem.TestInt);
//	`log(SaveSystem.TransTestInt);
}

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
	if(Role != Role_Authority && !Placeable.IsReplicable())
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
	`log("Received AddTicket:"@Ticket.TicketID@Ticket.ModIndex@Ticket.ModPlaceableIndex@Ticket.GridLocation@Ticket.Parent);
	if(TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), ConvertIndexesToPlaceable(Ticket.ModIndex, Ticket.ModPlaceableIndex),
		Ticket.Parent, Ticket.GridLocation) != None)
	{
		ClientHandleTicket(Ticket.TicketID, TRUE);
	}
	else
	{
		ClientHandleTicket(Ticket.TicketID, FALSE);
	}
}

reliable client function ClientHandleTicket(int TicketID, bool bAllowTicket)
{
	local byte Index;
	local AddTicket Ticket;
	Index = PendingTickets.find('TicketID', TicketID);
	if(Index != -1)
	{
		`log("Got our ticket back!"@bAllowTicket);
		Ticket = PendingTickets[Index];
		if(bAllowTicket)
		{
			AddLocalPlaceable(ConvertIndexesToPlaceable(Ticket.ModIndex, Ticket.ModPlaceableIndex), Ticket.Parent, Ticket.GridLocation);
			PendingTickets.Remove(Index, 1);
			if(PendingTickets.Length == 0)
			{
				NextTicketID = 0;
			}
		}
		else
		{

		}
	}
	else
	{
		`log("Ticket somehow does not exist?"@TicketID);
	}
}

simulated function AddLocalPlaceable(TowerPlaceable Placeable, TowerBlock Parent, out Vector GridLocation)
{
	local Vector SpawnLocation;
	SpawnLocation = class'TowerGame'.static.GridLocationToVector(GridLocation);
	Placeable.AttachPlaceable(Placeable, Parent, GetTower().NodeTree, SpawnLocation, GridLocation);
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
	OutTicket.TicketID = NextTicketID;
	OutTicket.GridLocation = GridLocation;
	OutTicket.Parent = Parent;
	
	ConvertPlaceableToIndexes(Placeable, OutTicket.ModIndex, OutTicket.ModPlaceableIndex);
	NextTicketID++;
	PendingTickets.AddItem(OutTicket);
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

function RemovePlaceable(TowerPlaceable Placeable)
{
	ServerRemovePlaceable(Placeable);
}

reliable server function ServerRemovePlaceable(TowerPlaceable Placeable)
{
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
	CollisionType=COLLIDE_BlockAll
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
	End Object
	CollisionComponent=CollisionCylinder
}