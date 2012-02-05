class TowerPlayerController extends GamePlayerController
	implements(SavableDynamic)
	dependson(TowerSaveSystem)
	config(Tower);

/** Save IDs. */
const LOCATION_X = "L_X";
const LOCATION_Y = "L_Y";
const LOCATION_Z = "L_Z";
const ROTATION_PITCH = "R_P";
const ROTATION_YAW = "R_Y";
const ROTATION_ROLL = "R_R";

var float NextAdminCmdTime;

var TowerSaveSystem SaveSystem;
var byte PreviewAreaIndex;
`if(`isdefined(DEBUG))
var TowerEnemyController PossessedPawnController;
`endif

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'Tower.TowerSaveSystem';
}

exec function DevLogin()
{
	if(WorldInfo.ComputerName == "JAMESB-PC" && WorldInfo.NetMode == NM_ListenServer)
	{
		AdminLogin("DbgPassword");
		AddCheats(true);
	}
	else
	{
		`log("Devs only.");
	}
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	if(Role == Role_Authority && TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI == None)
	{
		TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI = TowerPlayerReplicationInfo(PlayerReplicationInfo);
	}
}

state DebugEnemySpectating
{

}

state PlayerFlying
{
	/*function ProcessMove( float DeltaTime, vector newAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( (Pawn != None) && (Pawn.Acceleration != newAccel) )
		{
			Pawn.Acceleration = newAccel;
		}
	}*/

	function MoveAutonomous(float DeltaTime, byte CompressedFlags, vector newAccel, rotator DeltaRot)
	{
		local EDoubleClickDir DoubleClickMove;

		if ( (Pawn != None) && Pawn.bHardAttach )
			return;

		DoubleClickMove = SavedMoveClass.static.SetFlags(CompressedFlags, self);
		HandleWalking();

		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);

		ProcessMove(DeltaTime, newAccel, DoubleClickMove, DeltaRot);

		if ( Pawn != None )
		{
			Pawn.AutonomousPhysics(DeltaTime);
		}
		else
		{
			AutonomousPhysics(DeltaTime);
		}
		bDoubleJump = false;
		//`log("Role "$Role$" moveauto time "$100 * DeltaTime$" ("$WorldInfo.TimeDilation$")");
	}

	function PlayerMove(float DeltaTime)
	{
		Super.PlayerMove(DeltaTime);
		/*
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		Pawn.Acceleration = PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1);;
		Pawn.Acceleration = Pawn.AccelRate * Normal(Pawn.Acceleration);

		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);
		// Update rotation.
		UpdateRotation( DeltaTime );

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		*/
	}
}

/**
//@LOOKATME - Too much hassle. I can't think of a simple way to associate a TowerPlayerController
with its PRI, so this might conflict with split-screen.
state PlayerInactive extends PlayerFlying
{
	ignores AddBlock, RemoveBlock;
}
*/

exec function StartFire(optional byte FireModeNum)
{
	TowerHUD(myHUD).OnMouseClick(FireModeNum);
}

exec function StopFire(optional byte FireModeNum)
{
	TowerHUD(myHUD).OnMouseRelease(FireModeNum);
}

exec function ToggleBuildMenu(bool Toggle)
{
//	`log("TOGGLEBUILDMENU:"@Toggle);
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

//@TODO - Can't this just directly call a reliable server function in its Tower?
exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

exec function QuickSave();

exec function QuickLoad();

exec function SaveGame(string FileName, optional bool bUseJSON)
{
	local SaveSystemJSON JSONSave;
	if(TowerGameReplicationInfo(WorldInfo.GRI).bRoundInProgress)
	{
		`log("Trying to save while the round is in progress! This isn't allowed!");
	}
	if(bUseJSON)
	{
		JSONSave = new class'SaveSystemJSON';
		JSONSave.SaveGame("TEST", self);
	}
	else
	{
		SaveSystem.SaveGame(FileName, false, self);
	}
}

exec function LoadGame(string FileName/*, bool bTowerOnly*/)
{
	if(SaveSystem.CheckSaveExist(FileName))
	{
		ConsoleCommand("open"@WorldInfo.GetMapName(true)$"?LoadGame="$FileName);
	}
	else
	{
		`log("Save file:"@"'"$FileName$"'"@"does not exist.",,'Loading');
	}
//	SaveSystem.LoadGame(FileName, bTowerOnly, self);
}

exec function OpenBugReportWindow()
{

}

function AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, out IVector GridLocation)
{
	if(!GetTPRI().Tower.IsInState('Inactive'))
	{
		ServerAddBlock(BlockArchetype, Parent, GridLocation);
	}
	//TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), Placeable, Parent, GridLocation);
}

reliable server function ServerAddBlock(TowerBlock BlockArchetype, TowerBlock Parent, IVector GridLocation)
{
	if(GetTower().HasBudget(BlockArchetype.PurchasableComponent.Cost))
	{
		if(TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockArchetype, Parent, GridLocation) != None)
		{
			GetTower().ConsumeBudget(BlockArchetype.PurchasableComponent.Cost);
		}
		else
		{
			`log("Failed to add block of Archetype:"@BlockArchetype@"Parent:"@Parent@"GridLocation:"@GridLocation.X@GridLocation.Y@GridLocation.Z,,'Error');
		}
	}
}

/** Called from TowerHUD::OnMouseClick if a valid TowerPlaceable is selected for removal. */
function RemoveBlock(TowerBlock Block)
{
	if(!GetTPRI().Tower.IsInState('Inactive'))
	{
		ServerRemoveBlock(Block);
	}
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	// It's possible for a client to send multiple ServerRemoveBlock() calls for the same block, which won't exist on
	// the server past the first call.
	if(Block == None)
	{
		if(WorldInfo.NetMode == NM_StandAlone)
		{
			`warn("ServerRemoveBlock() passed None in an NM_StandAlone game. How did this happen?");
		}
		return;
	}
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), Block);
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

reliable client event WaitFor(float Seconds)
{
	IgnoreMoveInput(true);
	IgnoreLookInput(true);
	`log("Server suggests waiting for"@Seconds@"seconds. Will do.",,'CDNet');
	SetTimer(Seconds, false, NameOf(DoneWaiting));
}

private event DoneWaiting()
{
	local PlayerReplicationInfo PRI;
	if(HaveEssentialsReplicated())
	{
		`log("Done waiting, asking server for mods.",,'CDNet');
		WorldInfo.MyFractureManager.Destroy();
		foreach WorldInfo.GRI.PRIArray(PRI)
		{
			TowerPlayerReplicationInfo(PRI).Tower.Initialize();
		}
//		DebugReCalculateBlockLocations();
		GetTPRI().Tower.ReCalculateAllBlockLocations();
		RequestModList();
	}
	else
	{
		`log("Certain items still not replicated. Waiting another second.");
		SetTimer(1.0, false, NameOf(DoneWaiting));
	}
}

/**  */
private function bool HaveEssentialsReplicated()
{
	// Remember to pack the quickest checks first, as everything after the first FALSE won't get called.
	return WorldInfo.GRI != None && TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower != None
		&& AllBlockBasesReplicated() && AllBlockGridLocationsReplicated();
}

private function bool AllBlockBasesReplicated()
{
	return true;
}

private function bool AllBlockGridLocationsReplicated()
{
	return true;
}

//@NOTE - If there's concern about people reducing the wait time, have the server do a timestamp check.
reliable server function RequestModList()
{
	`log("Client done waiting, passing along ModList.",,'CDNet');
	LoadMods(TowerGameBase(WorldInfo.Game).RootMod.GetList(false));
}

reliable client event LoadMods(string ModList)
{
	`log("Received ModList!"@ModList,,'CDNet');
	TowerGameReplicationInfo(WorldInfo.GRI).RootMod = class'TowerGameBase'.static.LoadMods(ModList, true);
	`assert(TowerGameReplicationInfo(WorldInfo.GRI).RootMod != None);
	TowerHUD(myHUD).SetupBuildList();

	ResetPlayerMovementInput();
	class'Engine'.static.StopMovie(true);
}

function UpdateRoundNumber(byte NewRound)
{
	TowerHUD(myHUD).HUDMovie.SetRoundNumber(NewRound);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo);
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,430);
	Canvas.DrawText("Pawn:"@Pawn);
	Canvas.SetPos(0,440);
	Canvas.DrawText("Health:"@Pawn.Health);
	Canvas.SetPos(0,450);
	`if(`isdefined(DEBUG))
		Canvas.DrawText("PawnFactionOwner:"@PossessedPawnController.Owner);
	`endif
}

/******************************************
 Admin functions
 ******************************************/

function bool AdminCmdOk()
{
	//If we are the server then commands are ok
	if (WorldInfo.NetMode == NM_ListenServer && LocalPlayer(Player) != None)
	{
		return true;
	}

	if (WorldInfo.TimeSeconds < NextAdminCmdTime)
	{
		return false;
	}

	NextAdminCmdTime = WorldInfo.TimeSeconds + 5.0;
	return true;
}

exec function AdminLogin(string Password)
{
	if (Password != "" && AdminCmdOk() )
	{
		ServerAdminLogin(Password);
	}
}

reliable server function ServerAdminLogin(string Password)
{
	if ( (WorldInfo.Game.AccessControl != none) && AdminCmdOk() )
	{
		if ( WorldInfo.Game.AccessControl.AdminLogin(self, Password) )
		{
			WorldInfo.Game.AccessControl.AdminEntered(Self);
		}
	}
}

exec function AdminLogOut()
{
	if ( AdminCmdOk() )
	{
		ServerAdminLogOut();
	}
}

reliable server function ServerAdminLogOut()
{
	if ( WorldInfo.Game.AccessControl != none )
	{
		if ( WorldInfo.Game.AccessControl.AdminLogOut(self) )
		{
			WorldInfo.Game.AccessControl.AdminExited(Self);
		}
	}
}

// Execute an administrative console command on the server.
exec function Admin( string CommandLine )
{
	if (PlayerReplicationInfo.bAdmin)
	{
		ServerAdmin(CommandLine);
	}
}

reliable server function ServerAdmin( string CommandLine )
{
	local string Result;

	if ( PlayerReplicationInfo.bAdmin )
	{
		Result = ConsoleCommand( CommandLine );
		if( Result!="" )
			ClientMessage( Result );
	}
}

exec function AdminKickBan( string S )
{
	if (PlayerReplicationInfo.bAdmin)
	{
		ServerKickBan(S,true);
	}
}


exec function AdminKick( string S )
{
	if ( PlayerReplicationInfo.bAdmin )
	{
		ServerKickBan(S,false);
	}
}

/** Allows the local player or admin to kick a player */
reliable server function ServerKickBan(string PlayerToKick, bool bBan)
{
	if (PlayerReplicationInfo.bAdmin || LocalPlayer(Player) != none )
	{
		if (bBan)
		{
			WorldInfo.Game.AccessControl.KickBan(PlayerToKick);
		}
		else
		{
			WorldInfo.Game.AccessControl.Kick(PlayerToKick);
		}
	}
}

exec function AdminPlayerList()
{
	local PlayerReplicationInfo PRI;

	if (PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Player List:");
		foreach DynamicActors(class'PlayerReplicationInfo', PRI)
		{
			ClientMessage(PRI.PlayerID$"."@PRI.PlayerName @ "Ping:" @ INT((float(PRI.Ping) / 250.0 * 1000.0)) $ "ms)");
		}
	}
}

exec function AdminRestartMap()
{
	if (PlayerReplicationInfo.bAdmin)
	{
		ServerRestartMap();
	}
}

reliable server function ServerRestartMap()
{
	if ( PlayerReplicationInfo.bAdmin )
	{
		WorldInfo.ServerTravel("?restart", false);
	}
}

/********************************
Save/Loading
********************************/

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnSave(const SaveType SaveType)
{
	local JSonObject JSON;
	JSON = new class'JSonObject';
	if (JSON == None)
	{
		`warn(self@"Could not save!");
		return None;
	}

	JSON.SetFloatValue(LOCATION_X, Pawn.Location.X);
	JSON.SetFloatValue(LOCATION_Y, Pawn.Location.Y);
	JSON.SetFloatValue(LOCATION_Z, Pawn.Location.Z);

	JSON.SetIntValue(ROTATION_PITCH, Pawn.Rotation.Pitch);
	JSON.SetIntValue(ROTATION_YAW, Pawn.Rotation.Yaw);
	JSON.SetIntValue(ROTATION_ROLL, Pawn.Rotation.Roll);

	return JSON;
}

/** Called when loading a game. This function is intended for dynamic objects, who should create a new object and load
this data into it. */
public static event OnLoad(JSONObject Data, out const GlobalSaveInfo SaveInfo){}

DefaultProperties
{
	bCheatFlying=true
	CheatClass=class'TowerCheatManagerTD'

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