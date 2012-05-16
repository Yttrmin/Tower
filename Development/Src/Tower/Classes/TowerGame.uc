/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends TowerGameBase
	dependson(TowerMusicManager, MusicTrackDataStructures)
	config(Tower);

`define debugconfig `if(`isdefined(debug)) config `else `define debugconfig `endif
`define releasedefault x `if(`notdefined(debug)) x `else `define releasedefault `endif
`define GAMEINFO(dummy)
	`include(Tower\Classes\TowerStats.uci);
`undefine(GAMEINFO)

enum DifficultyLevel
{
	DL_Easy,
	DL_Normal,
	DL_Hard,
	DL_Impossible
};

enum MusicEvent
{
	ME_None,
	ME_StartBuilding,
	ME_StartRound,
	ME_EndRound
};

struct DifficultySettings
{
	var int BlockPriceMultiplier;
};

var TowerGameplayEventsWriter GameplayEventsWriter;
/** Number of factions that either have enemies alive or the capability to spawn more. */
var private byte RemainingActiveFactions;
var privatewrite DifficultyLevel Difficulty;
var const config float CoolDownTime;
var const config array<String> FactionAIs;
var const config bool bLogGameplayEvents;
var const config float GameplayEventsHeartbeatDelta;
var const config bool bUsePlayerPawns;

/** A box that contains every Block. Never shrinks. */
var privatewrite IBox WorldBounds;

/** Path to a TowerMusicList. It will be DynamicLoadObject()'d. */
var globalconfig string MusicListPath;
var TowerMusicList CurrentMusicList;

var array<TowerSpawnPoint> SpawnPoints; //,InfantryPoints, ProjectilePoints, VehiclePoints;

/** The root TowerStart for the world, represents space (0,0,0) for GridLocations. Typically the first player's spot. */
var TowerStart RootTowerStart;

event PostBeginPlay()
{
//	local TowerModInfo ZMOd;
	Super.PostBeginPlay();
	if(bLogGameplayEvents)
	{
		GameplayEventsWriter = new(Self) class'TowerGameplayEventsWriter';
		GameplayEventsWriter.StartLogging(GameplayEventsHeartbeatDelta);
		`log("Gameplay logging enabled.");
		`RecordGameIntStat(MAX_EVENTID, 12345);
	}
	CurrentMusicList = TowerMusicList(DynamicLoadObject(MusicListPath, class'TowerMusicList', false));
	PopulateSpawnPointArrays();
	CheckTowerStarts();
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		class'Engine'.static.StopMovie(true);
	}
//	ZMod = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject("MyModd.ZModModInfo",class'TowerModInfo',false)));
//	StartNextRound();
}

event PreExit()
{
	if(GameplayEventsWriter != None)
	{
		GameplayEventsWriter.EndLogging();
	}
	`log("Shutting down!");
}

event PostLogin(PlayerController NewPlayer)
{
	local TowerFactionHuman Faction;
	Super.PostLogin(NewPlayer);
	AddTower(TowerPlayerController(NewPlayer), !bPendingLoad);
	if(bPendingLoad)
	{
		if(WorldInfo.NetMode == NM_DedicatedServer)
		{
			TowerPlayerController(NewPlayer).SaveSystem = new class'TowerSaveSystem';
		}
		if(!TowerPlayerController(NewPlayer).SaveSystem.LoadGame(PendingLoadFile, false, TowerPlayerController(NewPlayer)))
		{
			`log("Failed to load file"@"'"$PendingLoadFile$"' (Should have NO extension)! Does the file exist?"
				@"It might be from a previous version of save files that is no longer supported. If that's the case"
				@"there's no solution to it for now.",,'Error');
			`log("Continuing as a new game due to loading failure.",,'Loading');
			AddRootBlock(TowerPlayerController(NewPlayer));
		}
		if(WorldInfo.NetMode == NM_DedicatedServer)
		{
			TowerPlayerController(NewPlayer).SaveSystem = None;
		}
		bPendingLoad = false;
		PendingLoadFile = "";
	}

	// Lazy initialize the Human faction if needed, and then add the NewPlayer to it.
	Faction = GetHumanFaction();
	if(Faction == None)
	{
		Faction = TowerFactionHuman(AddFaction(class'TowerFactionHuman', FL_None));
	}
	Faction.AddToTeam(NewPlayer);
	if(NewPlayer.Pawn == None)
	{
		//@TODO - bDelayedStart == true means RestartPlayer() isn't called for clients, so we do it here.
		RestartPlayer(newPlayer);
	}
	if(!MatchIsInProgress())
	{
		StartMatch();
	}
	UpdatePlayerCount();
	//@LOOKATME - No NO NO NO NO! This will completely destroy any clients if you uncomment! NEVER uncomment!
////Controller.SetOwner(Faction);
}

private final function TowerFactionHuman GetHumanFaction()
{
	local TeamInfo Faction;
	foreach GameReplicationInfo.Teams(Faction)
	{
		if(TowerFactionHuman(Faction) != None)
		{
			return TowerFactionHuman(Faction);
		}
	}
	return None;
}

//
// Player exits.
//
function Logout( Controller Exiting )
{
	//@TODO - Remove faction.
	Super.Logout(Exiting);
	// NumPlayers reflects how many players excluding Exiting. So on a dedicated server it can be 0.
	// The server calls this too when logging out, which will trigger an accessed none when we access the HUD.
	if(Exiting.RemoteRole == ROLE_AutonomousProxy)
	{
		UpdatePlayerCount();
	}
}

private final function UpdatePlayerCount()
{
	//@TODO - Update number for clients.
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		TowerHUD(GetALocalPlayerController().myHUD).HUDMovie.
				SetVariableString("_root.PlayerCount.text", String(NumPlayers));
	}
}

function RestartPlayer(Controller NewPlayer)
{
	local Vector SpawnLocation;
	local Rotator SpawnRotation;
	if(WorldInfo.NetMode != NM_DedicatedServer && TowerPlayerController(NewPlayer).SaveSystem.bLoaded)
	{
		SpawnLocation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.L;
		SpawnRotation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.R;
	}
	else
	{
		SpawnLocation = Vect(500,200,90);
	}
	if(bUsePlayerPawns)
	{
		if (NewPlayer.Pawn == None)
		{
			NewPlayer.Pawn = Spawn(DefaultPawnClass,,,SpawnLocation, SpawnRotation);
		}
		if (NewPlayer.Pawn == None)
		{
			`log("failed to spawn player at ");
			NewPlayer.GotoState('Dead');
			if ( PlayerController(NewPlayer) != None )
			{
				PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
			}
		}
		else
		{
			NewPlayer.Possess(NewPlayer.Pawn, false);
			NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);
			SetPlayerDefaults(NewPlayer.Pawn);
			NewPlayer.GotoState('PlayerFlying');
		}
		if( bRestartLevel && WorldInfo.NetMode!=NM_DedicatedServer && WorldInfo.NetMode!=NM_ListenServer )
		{
			`warn("bRestartLevel && !server, abort from RestartPlayer"@WorldInfo.NetMode);
			return;
		}
	}
	else
	{
		NewPlayer.GotoState('PawnLess');
	}
}

function PopulateSpawnPointArrays()
{
	local TowerSpawnPoint Point;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		Point.Faction = GetPointFactionLocation(Point.Location);
		SpawnPoints.AddItem(Point);
	}
}

final function CheckTowerStarts()
{

}

function GenericPlayerInitialization(Controller C)
{
	local PlayerController PC;

	PC = PlayerController(C);
	if (PC != None)
	{
		// Keep track of the best host to migrate to in case of a disconnect
		UpdateBestNextHosts();

		// Notify the game that we can now be muted and mute others
		UpdateGameplayMuteList(PC);

		// tell client what hud class to use
		PC.ClientSetHUD(HudType);

		ReplicateStreamingStatus(PC);

		// see if we need to spawn a CoverReplicator for this player
		if (CoverReplicatorBase != None)
		{
			PC.SpawnCoverReplicator();
		}

		// Set the rich presence strings on the client (has to be done there)
		PC.ClientSetOnlineStatus();
	}

	if (BaseMutator != None)
	{
		BaseMutator.NotifyLogin(C);
	}
}

exec function StartGame()
{
	StartMatch();
}

function StartMatch()
{
	local TowerFactionAI Archetype;
	local byte i;
	`log("StartMatch!");
	Super.StartMatch();
//	AddFaction(class'TowerFactionHuman', FL_None);
	//;PosX, PosY, NegX, NegY
	for(i = 0; i < 4 && i+1 <= FactionAIs.length; i++)
	{
		Archetype = TowerFactionAI(DynamicLoadObject(FactionAIs[i], class'TowerFactionAI', true));
		AddFaction(Archetype.class, FactionLocation(1+i), Archetype);
	}
	GotoState('CoolDown');
}

private final function TowerFaction AddFaction(class<TowerFaction> FactionClass, FactionLocation Faction, 
	optional TowerFactionAI Archetype)
{
	local TowerFaction NewFaction;
	local int TeamIndex;
	local array<TowerSpawnPoint> FactionSpawnPoints;
	local TowerSpawnPoint Point;

	TeamIndex = GameReplicationInfo.Teams.Length;;
	NewFaction = Spawn(FactionClass,,,,, Archetype);
	NewFaction.TeamIndex = TeamIndex;
	NewFaction.Faction = Faction;
	if(TowerFactionAI(NewFaction) != None)
	{
		// Fill an array of spawn points for the AI.
		foreach SpawnPoints(Point)
		{
			if(Point.Faction == Faction)
			{
				FactionSpawnPoints.AddItem(Point);
			}
		}
		TowerFactionAI(NewFaction).Hivemind = HiveMind;
		TowerFactionAI(NewFaction).ReceiveSpawnPoints(FactionSpawnPoints);
	}
	GameReplicationInfo.SetTeam(TeamIndex, NewFaction);
	return NewFaction;
}

function AddTower(TowerPlayerController Player, bool bAddRootBlock, optional string TowerName="")
{
	local Tower Tower;
	
	TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower = Spawn(class'Tower', self);
	Tower = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower;
	Tower.OwnerPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	// Initial budget!
	//@FIXME
	Tower.Budget = 99999;
//	TPRI.Tower.Initialize(TPRI);
	if(bAddRootBlock)
	{
		AddRootBlock(Player);
	}
//	AddBlock(TPRI.Tower, class'TowerModInfo_Tower'.default.ModBlockInfo[0], None, GridLocation, true);
	if(TowerName != "")
	{
		SetTowerName(Tower, TowerName);
	}
	Tower.Initialize();
}

function AddRootBlock(TowerPlayerController Player)
{
	local Tower Tower;
	local IVector GridLocation;
	// Need to make this dependent on player count in future.
	//@FIXME - This can be done a bit more cleanly and safely. Define in map maybe?
	GridLocation.X = 4*(NumPlayers-1);
	
	Tower = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower;
	Tower.SetRootBlock(TowerBlockRoot(AddBlock(Tower, RootArchetype, None, GridLocation)));
	//@FIXME - Have Root do this by itself?
	Hivemind.OnRootBlockSpawn(Tower.Root);
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}

event FactionInactive(TowerFactionAI Faction)
{
	`warn(Faction@"called FactionInactive when not in RoundInProgress!");
}

event RootDestroyed(TowerPlayerReplicationInfo PRI)
{
	PRI.Tower.Disabled();
	if(!AnyActiveTowers())
	{
		GotoState('GameOver');
	}
}

function bool AnyActiveTowers()
{
	// If this is slow try looking through PRIs instead or something.
	local Tower Tower;
	foreach DynamicActors(class'Tower', Tower)
	{
		if(!Tower.IsInState('Inactive'))
		{
			return true;
		}
	}
	return false;
}

function bool IsRoundInProgress()
{
	`log("RoundInProgress called outside proper states!"@GetStateName());
	return false;
}

function UpdateMusic(MusicEvent Event)
{
	local MusicTrackStruct NewTrack;
	switch(Event)
	{
	case ME_None:
		break;
	case ME_StartBuilding:
		NewTrack = CurrentMusicList.BuildMusic[Rand(CurrentMusicList.BuildMusic.Length)];
		break;
	case ME_StartRound:
		NewTrack = CurrentMusicList.RoundMusic[Rand(CurrentMusicList.RoundMusic.Length)];
		break;
	}
	WorldInfo.UpdateMusicTrack(NewTrack);
}

function ToggleShowHUDCoolDown(bool bVisible)
{
	local TowerPlayerController Controller;
	foreach LocalPlayerControllers(class'TowerPlayerController', Controller)
	{
		TowerHUD(Controller.myHUD).HUDMovie.SetVariableBool("_root.CoolDownText._visible", bVisible);
		TowerHUD(Controller.myHUD).HUDMovie.SetVariableBool("_root.CoolDownTime._visible", bVisible);
	}
}

state CoolDown
{
	event BeginState(Name PreviousStateName)
	{
		UpdateMusic(ME_StartBuilding);
		SetTimer(CoolDownTime, false, NameOf(CoolDownExpire));
		SetTimer(1, true, NameOf(UpdateHUDCoolDown));
		ToggleShowHUDCoolDown(true);
		UpdateHUDCoolDown();
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
	}

	//@DEBUG
	exec function SkipCoolDown()
	{
		ClearTimer(NameOf(CoolDownExpire));
		CoolDownExpire();
	}

	event CoolDownExpire()
	{
		GotoState('RoundInProgress');
	}

	event UpdateHUDCoolDown()
	{
		local TowerPlayerController Controller;
		foreach LocalPlayerControllers(class'TowerPlayerController', Controller)
		{
			TowerHUD(Controller.myHUD).HUDMovie.SetVariableString("_root.CoolDownTime.text", 
				String(Round(GetTimerRate(NameOf(CoolDownExpire)) - GetTimerCount(NameOf(CoolDownExpire)))));
		}
	}

	function bool IsRoundInProgress()
	{
		return false;
	}

	event EndState(Name NextStateName)
	{
		ClearTimer(NameOf(CoolDownExpire));
		ClearTimer(NameOf(UpdateHUDCoolDown));
	}
}

state RoundInProgress
{
	event BeginState(Name PreviousStateName)
	{
		local TeamInfo Faction;
		local int BudgetPerFaction;
		UpdateMusic(ME_StartRound);
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
		IncrementRound();
		ToggleShowHUDCoolDown(false);
		CalculateRemainingActiveFactions();
		//@FIXME - Remove +1
		BudgetPerFaction = 50 / (GetFactionAICount()+1);
		foreach GameReplicationInfo.Teams(Faction)
		{
			if(TowerFactionAI(Faction) != None)
			{
				TowerFactionAI(Faction).RoundStarted(BudgetPerFaction);
			}
		}
	}

	//@DEBUG
	exec function SkipRound()
	{
		local TeamInfo Faction;
		foreach GameReplicationInfo.Teams(Faction)
		{
			TowerFaction(Faction).GoInActive();
		}
	}

	/** Increments the round number and sends it all PlayerControllers. */
	function IncrementRound()
	{
		TowerGameReplicationInfo(GameReplicationInfo).Round++;
		// Force update Round for the server since it won't get replicated to it.
		TowerGameReplicationInfo(GameReplicationInfo).ReplicatedEvent('Round');
	}

	/** */
	event FactionInactive(TowerFactionAI Faction)
	{
		`log(Faction@"is now inactive. RemainingActiveFactions:"@RemainingActiveFactions,,'Round');
		RemainingActiveFactions--;
		TriggerGlobalEventClass(class'SeqEvent_FactionInactive', Faction, 0);
		if(RemainingActiveFactions <= 0)
		{
			`log("No more active factions, cooling down!",,'Round');
			GotoState('CoolDown');
		}
	}

	event EndState(Name NextStateName)
	{
		local TeamInfo Faction;
		foreach GameReplicationInfo.Teams(Faction)
		{
			if(TowerFactionAI(Faction) != None)
			{
				TowerFactionAI(Faction).RoundEnded();
			}
		}
	}

	function bool IsRoundInProgress()
	{
		return true;
	}
}

state GameOver
{
	final function NotifyGameOver()
	{
		local TeamInfo Faction;
		foreach GameReplicationInfo.Teams(Faction)
		{
			TowerFaction(Faction).OnGameOver();
		}
	}
Begin:
	`log("GAME OVER. IMAGINE A COOL CINEMATIC HERE.");
	NotifyGameOver();
	DrawDebugString(Vect(0,0,400), "GAME OVER");
	DrawDebugString(Vect(0,0,256), "* IMAGINE A COOL GAME OVER CINEMATIC HERE *");
}

function byte GetFactionAICount()
{
	local TeamInfo Faction;
	local byte Count;
	foreach GameReplicationInfo.Teams(Faction)
	{
		if(TowerFactionAI(Faction) != None)
		{
			Count++;
		}
	}
	return Count;
}

function CalculateRemainingActiveFactions()
{
	RemainingActiveFactions = GetFactionAICount();
}

function TowerBlock AddBlock(Tower Tower, TowerBlock BlockArchetype, TowerBlock Parent, 
	out IVector GridLocation)
{
	local TowerBlock Block;
	`assert(BlockArchetype != None);
//	if((Parent != None && TowerBlockModule(Parent) == None && Parent.IsInState('Stable')) 
//		|| BlockArchetype.class == class'TowerBlockRoot' || TowerGame(WorldInfo.Game).bPendingLoad)
	if(CanAddBlock(GridLocation, Parent, Tower) && (Parent != None && TowerBlockModule(Parent) == None 
		&& Parent.IsInState('Stable')) || BlockArchetype.class == class'TowerBlockRoot' || bPendingLoad)
	{
		Block = Tower.AddBlock(BlockArchetype, Parent, GridLocation);

		ExpandBoundsTo(Block.GridLocation);
		/*
		if(Block != None)
		{
			`RecordGamePositionStat(PLAYER_SPAWNED_BLOCK, SpawnLocation, 5);
		}
		*/
	}
	return Block;
}

/** Expands the world bounds to GridLocation +/-1. */
final function ExpandBoundsTo(const out IVector GridLocation)
{
	WorldBounds.Min.X = Min(WorldBounds.Min.X, GridLocation.X-1);
	WorldBounds.Min.Y = Min(WorldBounds.Min.Y, GridLocation.Y-1);
	// A* throws away all nodes where Z < 0 anyways.
	WorldBounds.Min.Z = Min(WorldBounds.Min.Z, Gridlocation.Z-1);
	WorldBounds.Max.X = Max(WorldBounds.Max.X, GridLocation.X+1);
	WorldBounds.Max.Y = Max(WorldBounds.Max.Y, GridLocation.Y+1);
	WorldBounds.Max.Z = Max(WorldBounds.Max.Z, GridLocation.Z+1);
}

function RemoveBlock(Tower Tower, TowerBlock Block)
{
	Tower.RemoveBlock(Block);
}

/** Returns TRUE if GridLocation is on the grid and there's no Unstable blocks currently falling into GridLocation. */
function bool CanAddBlock(out const IVector GridLocation, TowerBlock Parent, Tower Tower)
{
	return (IsGridLocationOnGrid(GridLocation) && (Parent == None || !IsBlockFallingOntoBlock(GridLocation, Parent))
		&& !IsGridLocationOccupied(GridLocation, Tower));
}

/** Returns TRUE if there is a TowerBlock (excluding Air) at this GridLocation. */
function bool IsGridLocationOccupied(out const IVector GridLocation, Tower Tower)
{
	local Vector TestLocation;
	local TowerBlock Block;
	TestLocation = Tower.GridLocationToVector(GridLocation);
	foreach CollidingActors(class'TowerBlock', Block, 32, TestLocation)
	{
		if(TowerBlockAir(Block) == None)
		{
			return true;
		}
	}
	return false;
}

/** Returns TRUE if the GridLocation is inside the bounds specified in TowerMapInfo. */
function bool IsGridLocationOnGrid(out const IVector GridLocation)
{
	local int MapXBlocks; 
	local int MapYBlocks; 
	local int MapZBlocks;
	MapXBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).XBlocks;
	MapYBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).YBlocks;
	MapZBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).ZBlocks;
	return	((GridLocation.X <= MapXBlocks/2 && GridLocation.X >= -MapXBlocks/2) && 
			(GridLocation.Y <= MapYBlocks/2 && GridLocation.Y >= -MapYBlocks/2) &&
			(GridLocation.Z <= MapZBlocks/2 && GridLocation.Z >= -MapZBlocks/2));
}

/** Returns TRUE if there are any Unstable blocks in the process of falling into TestGridLocation. */
function bool IsBlockFallingOntoBlock(out const IVector TestGridLocation, TowerBlock Block)
{
	local TowerBlock IteratorBlock;
	local Vector HitLocation, HitNormal, Extent, Start, End;

	Start = Block.Location;
	Start.Z -= 128;

	End = Start;
	End.Z += 512;

	Extent = Vect(384, 384, 0);

	foreach TraceActors(class'TowerBlock', IteratorBlock, HitLocation, HitNormal, End, Start, Extent)
	{
		if(IteratorBlock.IsInState('Unstable') || IteratorBlock.IsChildState(IteratorBlock.GetStateName(), 'Unstable'))
		{
			if(IteratorBlock.GridLocation - Vect(0,0,1) == TestGridLocation)
			{
				return true;
			}
		}
	}
	return false;
}

function int GetRemainingTime()
{
	return (GetTimerRate('GameTimerExpired') - GetTimerCount('GameTimerExpired')+1);
}

public event OnLoadGame(JSONObject Data)
{
	Super.OnLoadGame(Data);

}

DefaultProperties
{
	MaxPlayersAllowed=4
	PlayerControllerClass=class'Tower.TowerPlayerController'
	PlayerReplicationInfoClass=class'Tower.TowerPlayerReplicationInfo'
	GameReplicationInfoClass=class'Tower.TowerGameReplicationInfo'
	DefaultPawnClass=class'Tower.TowerPlayerPawn'
	HUDType=class'Tower.TowerHUD'
	OnlineGameSettingsClass=class'Tower.TowerGameSettingsTD'

	Borders[0]=(X=-1,Y=1,Z=0)
	Borders[1]=(X=1,Y=1,Z=0)
	Borders[2]=(X=1,Y=-1,Z=0)
	Borders[3]=(X=-1,Y=-1,Z=0)
}