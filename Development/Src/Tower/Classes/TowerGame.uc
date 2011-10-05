/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends TowerGameBase
	dependson(TowerMusicManager)
	config(Tower);

`define debugconfig `if(`isdefined(debug)) config `else `define debugconfig `endif
`define releasedefault x `if(`notdefined(debug)) x `else `define releasedefault `endif
`define GAMEINFO(dummy)
	`include(Tower\Classes\TowerStats.uci);
`undefine(GAMEINFO)

enum FactionLocation
{
	FL_None,
	FL_PosX,
	FL_NegX,
	FL_PosY,
	FL_NegY,
	FL_All
};

enum DifficultyLevel
{
	DL_Easy,
	DL_Normal,
	DL_Hard,
	DL_Impossible
};

struct DifficultySettings
{
	var int BlockPriceMultiplier;
};

//@DEPRECATED - GameReplicationInfo::Teams does this.
var deprecated array<TowerFaction> Factions;
var TowerGameplayEventsWriter GameplayEventsWriter;
/** Number of factions that either have enemies alive or the capability to spawn more. */
var private byte RemainingActiveFactions;
var protected byte Round;
var privatewrite DifficultyLevel Difficulty;
var const config float CoolDownTime;
var const config array<String> FactionAIs;
var const config bool bLogGameplayEvents;
var const config float GameplayEventsHeartbeatDelta;

var array<TowerSpawnPoint> SpawnPoints; //,InfantryPoints, ProjectilePoints, VehiclePoints;

/** The root TowerStart for the world, represents space (0,0,0) for GridLocations. Typically the first player's spot. */
var TowerStart RootTowerStart;

var const Vector Borders[4];

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

event InitGame(string Options, out string ErrorMessage)
{
	Super.InitGame(Options, ErrorMessage);
}

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);
	AddTower(TowerPlayerController(NewPlayer), !bPendingLoad);
	if(bPendingLoad)
	{
		if(!TowerPlayerController(NewPlayer).SaveSystem.LoadGame(PendingLoadFile, false, TowerPlayerController(NewPlayer)))
		{
			`log("Failed to load file"@"'"$PendingLoadFile$"' (Should have NO extension)! Does the file exist?"
				@"It might be from a previous version of save files that is no longer supported. If that's the case"
				@"there's no solution to it for now.",,'Error');
			`log("Continuing as a new game due to loading failure.",,'Loading');
			AddRootBlock(TowerPlayerController(NewPlayer));
		}
		bPendingLoad = false;
		PendingLoadFile = "";
	}
	//@TODO - bDelayedStart == true means RestartPlayer() isn't called for clients, so we do it here.
	AddFaction(class'TowerFactionHuman', FL_None, NewPlayer);
	if(NewPlayer.Pawn == None)
	{
		RestartPlayer(newPlayer);
	}
	if(!MatchIsInProgress())
	{
		StartMatch();
	}
}

function RestartPlayer(Controller NewPlayer)
{
	local Vector SpawnLocation;
	local Rotator SpawnRotation;
	if(TowerPlayerController(NewPlayer).SaveSystem.bLoaded)
	{
		SpawnLocation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.L;
		SpawnRotation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.R;
	}
	else
	{
		SpawnLocation = Vect(500,200,90);
	}
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = Spawn(DefaultPawnClass,,,SpawnLocation, SpawnRotation);
	}
	if (NewPlayer.Pawn == None)
	{
		`log("failed to spawn player at "/*$StartSpot*/);
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

/** Returns the FactionLocation that the given point is in.
Useful for determining who's land the Point is on. */
function FactionLocation GetPointFactionLocation(Vector Point)
{
	if(Point dot Borders[0] > 0)
	{
		// NegX or PosY.
		if(Point dot Borders[1] > 0)
		{
			return FL_PosY;
		}
		else if(Point dot Borders[3] > 0)
		{
			return FL_NegX;
		}
	}
	// PosX or NegY.
	else if(Point dot Borders[1] > 0)
	{
		return FL_PosX;
	}
	else if(Point dot Borders[3] > 0)
	{
		return FL_NegY;
	}
	ScriptTrace();
	`warn("Determined FactionLocation was FL_None for point:"@Point$"!");
	return FL_None;
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

`if(`isdefined(DEBUG))
exec function DebugGetFactionLocation(Vector Point)
{
	`log(GetEnum(Enum'FactionLocation', GetPointFactionLocation(Point)));
}

exec function DebugKillAllTargetables()
{
	local Actor Targetable;
	foreach DynamicActors(class'Actor', Targetable, class'TowerTargetable')
	{
		Targetable.TakeDamage(999999, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
//	GotoState('CoolDown');
}

/** Forces the server and all clients to play this index on their OverrideMusic list. */
exec function DebugServerMusicForcePlay(byte Index)
{
	local TowerPlayerController Controller;
	Controller = TowerPlayerController(GetALocalPlayerController());
	PlaySound(Controller.MusicManager.CurrentMusicList.OverrideMusic[Index], false, false, true);
}

exec function DebugServerMusicForceStop()
{

}

exec function DebugListSpawnPoints()
{
	local TowerSpawnPoint Point;
	local array<TowerSpawnPoint> PosX, NegX, PosY, NegY;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		switch(Point.Faction)
		{
		case FL_PosX:
			PosX.AddItem(Point);
			break;
		case FL_PosY:
			PosY.AddItem(Point);
			break;
		case FL_NegX:
			NegX.AddItem(Point);
			break;
		case FL_NegY:
			NegY.AddItem(Point);
			break;
		default:
			`log(Point@"has no assigned faction!"@Point.Location);
			break;
		}
	}
	`log("=============================================================================");
	`log("FL_PosX Points:");
	foreach PosX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_PosY Points:");
	foreach PosY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegX Points:");
	foreach NegX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegY Points:");
	foreach NegY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("=============================================================================");
}

exec function DebugKillAllRootBlocks()
{
	local TowerPlayerController Controller;
	foreach WorldInfo.AllControllers(class'TowerPlayerController', Controller)
	{
		Controller.GetTower().Root.TakeDamage(99999, Controller, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
}

exec function DebugForceGarbageCollection(optional bool bFullPurge)
{
	WorldInfo.ForceGarbageCollection(bFullPurge);
}

exec function DebugAllBlocksToKActor()
{
	local TowerBlockStructural Block;
	local StaticMeshComponent ToKactor;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		`log(Block@Block.StaticMeshComponent@"GO");
		TOKactor = Block.StaticMeshComponent;
		class'KActorFromStatic'.static.MakeDynamic(TOKactor)
			.ApplyImpulse(Vect(0,0,1), 25000, Vect(0,0,0));
	}
}

exec function DebugRecursionStateTest()
{
	Spawn(class'TowerGameUberTest').DebugStartRecursionTest();
}

exec function DebugUberBlockTest()
{
	Spawn(class'TowerGameUberTest').Start(self);
}

exec function DebugStep()
{
	local TowerFaction Faction;
	foreach Factions(Faction)
	{
		if(TowerFactionAIAStar(Faction) != None)
		{
			TowerFactionAIAStar(Faction).Step();
		}
	}
}

/** STEAM */

final function OnReadFriends(bool bWasSuccessful)
{
	local array<OnlineFriend> Friends;
	local array<UniqueNetID> ToSpam;
	local OnlineFriend Friend;
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).GetFriendsList(0, Friends));
	//EOnlineFriendState always offline? Only refers to Cube Defense games? bIsOnline accurate.
	foreach Friends(Friend)
	{
		`log(Friend.NickName@Friend.FriendState@Friend.UniqueID.UID.A@Friend.UniqueID.UID.B@Friend.bIsOnline@Friend.bHasVoiceSupport);
		if(Friend.NickName == "TestBot 300")
		{
			/** Nope. Opens up their steam community page in the overlay. */
//			OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).RemoveFriend(0,Friend.UniqueID);
		}
		else if(Friend.NickName == "{Dic6} Galactic Pretty Boy")
		{
			ToSpam.AddItem(Friend.UniqueId);
			`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).SendGameInviteToFriends(0,ToSpam,"MYKE DID YOU GET THIS!?"));
		}
	}
}

final function OnReadFriendsForAvatars(bool bWasSuccessful)
{
	local array<OnlineFriend> Friends;
	local OnlineFriend Friend;
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).GetFriendsList(0, Friends);
	foreach Friends(Friend)
	{
		if(Friend.NickName != "[Lurking] KNAPKINATOR")
		OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadOnlineAvatar(Friend.UniqueID, OnReadAvatar);
	}
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadOnlineAvatar(LocalPlayer(GetALocalPlayerController().Player).GetUniqueNetID(), OnReadAvatar);
}

final function OnReadAvatar(const UniqueNetId PlayerNetId, Texture2D Avatar)
{
	local TowerBlockStructural Block;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		if(bool(Rand(2)))
		{
			Block.MaterialInstance.SetTextureParameterValue('BlockTexture', Avatar);
		}
	}
}


/** Steam is smart and won't just let you screw up people's stuff.
SendMessageToFriend() just opens the steam overlay with a chat window to whoever. */
final function AskMyke(out OnlineFriend Myke)
{
	local int i;
	for(i = 0; i < 5; i++)
	{
		`log(Myke.NickName@OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).
			SendMessageToFriend(0, Myke.UniqueID, "BEEP BOOP MYKE DID YOU GET THIS?!?!?!"));
	}
}
exec function DebugSteamUnlockAchievement(int AchievementID)
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).UnlockAchievement(0,AchievementID));
}

exec function DebugSteamShowAchievementsUI()
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ShowAchievementsUI(0));
}

exec function DebugSteamResetAchievements()
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ResetStats(true));
}

exec function DebugSteamListFriends()
{
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).AddReadFriendsCompleteDelegate(0, OnReadFriends);
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadFriendsList(0, 0);
}

exec function DebugSteamAddAvatars()
{
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).AddReadFriendsCompleteDelegate(0, OnReadFriendsForAvatars);
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadFriendsList(0, 0);
}

/** /STEAM */

exec function DebugJump()
{
	local TowerEnemyPawn Pawn;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', Pawn)
	{
		Pawn.DoJump(false);
	}
}

exec function DebugAITaunt()
{
	local TowerEnemyPawn Pawn;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', Pawn)
	{
		TowerEnemyController(Pawn.Controller).GotoState('Celebrating');
	}
}

exec function DebugDestructiblesToRigidBody()
{
	local ApexDestructibleActor Actor;
	foreach AllActors(class'ApexDestructibleActor', Actor)
	{
		`log("PHYS_RigidBody'ing"@Actor$"!");
		//Actor.TakeDamage(MaxInt, None, Actor.Location, Vect(0,0,0), class'DmgType_Telefragged');
		Actor.SetPhysics(PHYS_RigidBody);
		//Actor.StaticDestructibleComponent.WakeRigidBody();
	}
}

exec function DebugSpawnDestructible()
{
	Spawn(class'ApexDestructibleActorSpawnable',,, vect(0,0,1024),, ApexDestructibleActor(DynamicLoadObject("TestDestructible.DebugDestructibleSpawnableArchetype", class'ApexDestructibleActorSpawnable'))).SetPhysics(PHYS_RigidBody);
}
`endif

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
		AddFaction(Archetype.class, FactionLocation(1+i),, Archetype);
	}
	GotoState('CoolDown');
}


private final function AddFaction(class<TowerFaction> FactionClass, FactionLocation Faction, 
	optional PlayerController Controller, optional TowerFactionAI Archetype)
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
	//@DELETEME @DEPRECATED
	Factions[TeamIndex] = NewFaction;
	GameReplicationInfo.SetTeam(TeamIndex, NewFaction);
	NewFaction.AddToTeam(Controller);
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

state CoolDown
{
	event BeginState(Name PreviousStateName)
	{
		SetTimer(CoolDownTime, false);
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
	}

	//@DEBUG
	exec function SkipCoolDown()
	{
		ClearTimer();
		Timer();
	}

	event Timer()
	{
		GotoState('RoundInProgress');
	}

	function bool IsRoundInProgress()
	{
		return false;
	}
}

state RoundInProgress
{
	event BeginState(Name PreviousStateName)
	{
		local TowerFaction Faction;
		local int BudgetPerFaction;
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
		IncrementRound();
		CalculateRemainingActiveFactions();
		SendMusicEvent(ME_StartRound);
		//@FIXME - Remove +1
		BudgetPerFaction = 50 / (GetFactionAICount()+1);
		foreach Factions(Faction)
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
		local TowerFaction Faction;
		foreach Factions(Faction)
		{
			Faction.GoInActive();
		}
	}

	/** Increments the round number and sends it all PlayerControllers. */
	function IncrementRound()
	{
		Round++;
		TowerGameReplicationInfo(GameReplicationInfo).Round = Round;
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
		local TowerFaction Faction;
		foreach Factions(Faction)
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
		local TowerFaction Faction;
		foreach Factions(Faction)
		{
			Faction.OnGameOver();
		}
	}
Begin:
	`log("GAME OVER. IMAGINE A COOL CINEMATIC HERE.");
	NotifyGameOver();
	DrawDebugString(Vect(0,0,400), "GAME OVER");
	DrawDebugString(Vect(0,0,256), "* IMAGINE A COOL GAME OVER CINEMATIC HERE *");
}

function SendMusicEvent(MusicEvent Event)
{
	TowerGameReplicationInfo(GameReplicationInfo).MusicEvent = Event;
	TowerGameReplicationInfo(GameReplicationInfo).ReplicatedEvent('MusicEvent');
}

function byte GetFactionAICount()
{
	local TowerFaction Faction;
	local byte Count;
	foreach Factions(Faction)
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
	if(CanAddBlock(GridLocation, Parent))
	{
		Block = Tower.AddBlock(BlockArchetype, Parent, GridLocation);
		/*
		if(Block != None)
		{
			`RecordGamePositionStat(PLAYER_SPAWNED_BLOCK, SpawnLocation, 5);
		}
		*/
	}
	return Block;
}

function RemoveBlock(Tower Tower, TowerBlock Block)
{
	Tower.RemoveBlock(Block);
}

/** Returns TRUE if GridLocation is on the grid and there's no Unstable blocks currently falling into GridLocation. */
function bool CanAddBlock(out const IVector GridLocation, TowerBlock Parent)
{
	return (IsGridLocationOnGrid(GridLocation) && (Parent == None || !IsBlockFallingOntoBlock(GridLocation, Parent)));
}

static function Vector GridLocationToVector(out const IVector GridLocation, optional class<TowerBlock> BlockClass)
{
	local Vector NewBlockLocation;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256);
	NewBlockLocation.Y = (GridLocation.Y * 256);
	NewBlockLocation.Z = (GridLocation.Z * 256);
	//@TODO - Are we doing this here or what?
	// Pivot point in middle, bump it up.
//	NewBlockLocation.Z += 128;
	return NewBlockLocation;
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

DefaultProperties
{
	MaxPlayersAllowed=4
	PlayerControllerClass=class'Tower.TowerPlayerController'
	PlayerReplicationInfoClass=class'Tower.TowerPlayerReplicationInfo'
	GameReplicationInfoClass=class'Tower.TowerGameReplicationInfo'
	DefaultPawnClass=class'Tower.TowerPlayerPawn'
	HUDType=class'Tower.TowerHUD'

	Borders[0]=(X=-1,Y=1,Z=0)
	Borders[1]=(X=1,Y=1,Z=0)
	Borders[2]=(X=1,Y=-1,Z=0)
	Borders[3]=(X=-1,Y=-1,Z=0)
}