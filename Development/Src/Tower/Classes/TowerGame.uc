/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends FrameworkGame
	dependson(TowerModule)
	config(Tower);

enum Factions
{
	F_Debug,
	// F_Player represents all humans players in the game since it's co-op only.
	F_Player
};

var array<Tower> PlayerTowers;
var array<TowerFactionAI> FactionAIs;
var array<TowerSpawnPoint> InfantryPoints, ProjectilePoints, VehiclePoints;
var array<TowerModInfo> GameMods;

var array<TowerModInfo> Mods;
var config array<String> ModPackages;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	CheckForMods();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	PopulateSpawnPointArrays();
	AddFactionAIs();
	`log("PRI Count:"@GameReplicationInfo.PRIArray.Length);
//	StartNextRound();
}

event InitGame(string Options, out string ErrorMessage)
{
	Super.InitGame(Options, ErrorMessage);
}

event PreLogin(string Options, string Address, out string ErrorMessage)
{
	//@TODO - Check mod list in Options.
	// Tower|0.1;MyMod|1.0
	local int i;
	local TowerModInfo Mod;
	local String ModsList;
	local array<String> ModNames;

	local array<TowerModInfo> MissingMods;

	ModsList = ParseOption(Options, "Mods");
	ModNames = SplitString(ModsList);
	foreach GameMods(Mod)
	{
		if(ModNames.Find(Mod.ModName$Mod.Version) == -1)
		{
			MissingMods.AddItem(Mod);
		}
	}
	if(MissingMods.Length > 0)
	{
		ErrorMessage $= "Missing mods: ";
		foreach MissingMods(Mod, i)
		{
			if(i > 0)
			{
				ErrorMessage $= ", ";
			}
			ErrorMessage $= Mod.ModName$"("$Mod.Version$")";
		}
		ErrorMessage $= ". Can't join server!";
	}
	Super.PreLogin(Options, Address, ErrorMessage);
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController NewPlayer;
	NewPlayer = super.Login(Portal, Options, UniqueID, ErrorMessage);
	//TowerPlayerController(NewPlayer).GotoState('Master');
	return NewPlayer;
}

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);
	//@TODO - Maybe not make this automatic?
	AddTower(TowerPlayerController(NewPlayer));
}

function CheckForMods()
{
	local TowerPlayerReplicationInfo TPRI;
	//@TODO - Convert package name to class name and such.
	local class<TowerModInfo> ModInfo;

	local int i;
	local TowerModInfo Mod;
	local String ReplicatedModList;

	local String TMIClass;
	local TowerModInfo TMI;
	TPRI = Spawn(class'TowerPlayerReplicationInfo');
	`log("LOADING MODS");
	`log("GameMods:"@GameMods.Length);
	foreach TPRI.ModClasses(TMIClass, i)
	{
		`log("LOADING MOD:"@TMIClass);
		ModInfo = class<TowerModInfo>(DynamicLoadObject(TMIClass,class'class',false));
		`log("MOD CLASS:"@ModInfo);
		TMI = Spawn(ModInfo);
		TMI.PreInitialize(i);
		`log("MOD INFO:"@TMI@TMI.AuthorName@TMI.Description@TMI.Version);
		GameMods.AddItem(TMI);
	}
	`log("GameMods:"@GameMods.Length);
	foreach GameMods(Mod, i)
	{
		if(i > 0)
		{
			ReplicatedModList $= ";";
		}
		ReplicatedModList $= Mod.ModName;
	}
	`log("ReplicatedModList:"@ReplicatedModList);
	TowerGameReplicationInfo(GameReplicationInfo).ServerMods = ReplicatedModList;
	TPRI.Destroy();
}

function PopulateSpawnPointArrays()
{
	local TowerSpawnPoint Point;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		if(Point.bCanSpawnInfantry)
		{
			InfantryPoints.AddItem(Point);
		}
		if(Point.bCanSpawnProjectile)
		{
			ProjectilePoints.AddItem(Point);
		}
		if(Point.bCanSpawnVehicle)
		{
			VehiclePoints.AddItem(Point);
		}
	}
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

exec function LaunchMissile()
{

}

exec function StartGame()
{
	StartCoolDown();
}

function StartMatch()
{
	local Actor A;

	if ( MyAutoTestManager != None )
	{
		MyAutoTestManager.StartMatch();
	}

	// tell all actors the game is starting
	ForEach AllActors(class'Actor', A)
	{
		A.MatchStarting();
	}

	// start human players first
	StartHumans();

	// start AI players
	StartBots();

	bWaitingToStartMatch = false;

	StartOnlineGame();

	// fire off any level startup events
	WorldInfo.NotifyMatchStarted();
}

exec function SkipRound()
{
	ClearTimer('GameTimerExpired');
	GameTimerExpired(); 
}

function AddFactionAIs()
{
	FactionAIs.AddItem(Spawn(class'TowerFactionAIDebug'));
}

/** Very first part of a game, and happens between every round. */
function StartCoolDown()
{
	`log("Starting 5 second cooldown round!");
	SetCoolDownTimer(5);
}

function StartNextRound()
{
	local TowerFactionAI Faction;
	local int BudgetPerFaction;
	TowerGameReplicationInfo(GameReplicationInfo).NextRound();
	SetGameTimer(120);
	BudgetPerFaction = TowerGameReplicationInfo(GameReplicationInfo).MaxEnemyCount / FactionAIs.Length;
	foreach FactionAIs(Faction)
	{
		Faction.RoundStarted(BudgetPerFaction);
	}
}

function SetCoolDownTimer(float NewTime)
{
	SetTimer(NewTime, false, 'CoolDownTimerExpired');
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = NewTime;
	TowerGameReplicationInfo(WorldInfo.GRI).SetGameTimer();
}

event CoolDownTimerExpired()
{
	`log("Cool down over");
	StartNextRound();
}

function SetGameTimer(float NewTime)
{
	`log("Started"@NewTime@"second round.");
	SetTimer(NewTime, false, 'GameTimerExpired');
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = NewTime;
	TowerGameReplicationInfo(WorldInfo.GRI).SetGameTimer();
}

event GameTimerExpired()
{
	`log("Round over.");
	TowerGameReplicationInfo(WorldInfo.GRI).EndRound();
	StartCoolDown();
}

function AddTower(TowerPlayerController Player,  optional string TowerName="")
{
	local TowerPlayerReplicationInfo TPRI;
	local Vector GridLocation;
	TPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	//@BUG
	// For whatever reason PlayerController won't collide with children, so we're breaking
	// the ownership chain right here. There's probably a flag for child collision but
	// I can't find it.
	TPRI.Tower = Spawn(class'Tower');
	TPRI.Tower.OwnerPRI = TPRI;
//	TPRI.Tower.Initialize(TPRI);
	// Need to make this dependent on player count in future.
	//@FIXME - This can be done a bit more cleanly and safely. Define in map maybe?
	GridLocation.X = 8*(NumPlayers-1);
//	AddPlaceable(TPRI.Tower, Mods[0].ModBlocks[0], None, GridLocation);
	AddBlock(TPRI.Tower, class'TowerModInfo_Tower'.default.ModBlockInfo[0], None, GridLocation, true);
	if(TowerName != "")
	{
		SetTowerName(TPRI.Tower, TowerName);
	}
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}


function TowerPlaceable AddPlaceable(Tower Tower, TowerPlaceable Placeable, TowerBlock Parent, 
	out Vector GridLocation)
{
	local Vector SpawnLocation;
	SpawnLocation = GridLocationToVector(GridLocation);
	// Pivot point in middle, bump up.
	SpawnLocation.Z += 128;
	if(CanAddBlock(GridLocation))
	{
		return Tower.AddPlaceable(Placeable, Parent, SpawnLocation, GridLocation);
	}
	else
	{
		return None;
	}
}

function RemovePlaceable(Tower Tower, TowerPlaceable Placeable)
{

}


function TowerModule AddModule(Tower Tower, ModuleInfo Info, TowerBlock Parent,
	out Vector GridLocation)
{
	local Vector SpawnLocation;
	SpawnLocation = GridLocationToVector(GridLocation);
	if(CanAddBlock(GridLocation))
	{
		Parent.AddModule(Info, GridLocation);
	}
}

/** Ensures adding a block is allowed by the game rules, and then passes it along to Tower to spawn
it. */
function TowerBlock AddBlock(Tower Tower, BlockInfo Info, TowerBlock ParentBlock, 
	out Vector GridLocation, optional bool bRootBlock = false)
{
	local TowerBlock Block;
	local vector SpawnLocation;
	SpawnLocation =  GridLocationToVector(GridLocation, Info.BaseClass);
	// Pivot point is in middle, bump it up so we're not in the ground.
	SpawnLocation.Z += 128;
	if(CanAddBlock(GridLocation))
	{
		Block = Tower.AddBlock(Info, ParentBlock, SpawnLocation, GridLocation, 
			bRootBlock);
		Broadcast(Tower, "Block added");
	}
	else
	{
		Broadcast(Tower, "Could not add block");
	}
	return Block;
}

/** Removes block from a given grid location. Can't be removed if bRootBlock. Returns TRUE if removed.*/
function bool RemoveBlock(Tower CallingTower, TowerBlock Block)
{
	//@TODO - Check some conditions before arbitrarily removing blocks!
	if(Block != None)
	{
		if(!Block.bRootBlock)
		{
			return CallingTower.RemoveBlock(Block);
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
	/*
	//@TODO - Now that tracing works fine, do traces instead.
	//@DELETEME - All these broadcasts.
	local TowerBlock Block;
	local int OutBlockIndex;
	Block = GetBlockFromGrid(XBlock, YBlock, ZBlock, OutBlockIndex);
	if(Block == None)
	{
		Broadcast(None, "No block at given location");
		return false;
	}
	if(Block.bRootBlock)
	{
		Broadcast(None, "Block is bRootBlock, can't be destroyed.");
		return false;
	}
	else if(CallingTower != Block.Owner)
	{
		Broadcast(None, "A Tower asked to remove a block it didn't own, not allowed!");
		return false;
	}
	else
	{
		if(Tower(Block.Owner).RemoveBlock(OutBlockIndex))
		{
			Broadcast(None, "Block destroyed.");
			return true;
		}
		else
		{
			Broadcast(None, "Block can't be destroyed for unknown reason.");
			return false;
		}
	}
	*/
}

function bool CanAddBlock(out Vector GridLocation)
{
	return (IsGridLocationFree(GridLocation) && IsGridLocationOnGrid(GridLocation));
}

function Vector GridLocationToVector(out Vector GridLocation, optional class<TowerBlock> BlockClass)
{
	local int MapBlockWidth, MapBlockHeight;
	local Vector NewBlockLocation;
	MapBlockHeight = TowerMapInfo(WorldInfo.GetMapInfo()).BlockHeight;
	MapBlockWidth = TowerMapInfo(WorldInfo.GetMapInfo()).BlockWidth;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * MapBlockWidth);
	NewBlockLocation.Y = (GridLocation.Y * MapBlockWidth);
	// Z is the very bottom of the block.
	NewBlockLocation.Z = (GridLocation.Z * MapBlockHeight);
	return NewBlockLocation;
}

function bool IsGridLocationOnGrid(out Vector GridLocation)
{
	local int MapXBlocks; 
	local int MapYBlocks; 
	local int MapZBlocks;
	MapXBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).XBlocks;
	MapYBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).YBlocks;
	MapZBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).ZBlocks;
	if((GridLocation.X <= MapXBlocks/2 && GridLocation.X >= -MapXBlocks/2) && 
		(GridLocation.Y <= MapYBlocks/2 && GridLocation.Y >= -MapYBlocks/2) &&
		(GridLocation.Z <= MapZBlocks/2 && GridLocation.Z >= -MapZBlocks/2))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function bool IsGridLocationFree(out Vector GridLocation)
{
	return true;
}

function TowerBlock GetBlockFromGrid(int XBlock, int YBlock, int ZBlock, out int BlockIndex)
{
	/*
	// Seriously need a helper function to make grid vectors, or at least make all XBlocks etc into vectors.
	local Vector GridLocation;
	local TowerBlock Block;
	local PlayerReplicationInfo PRI;
	local TowerPlayerReplicationInfo TPRI;

	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	foreach GameReplicationInfo.PRIArray(PRI)
	{
		TPRI = TowerPlayerReplicationInfo(PRI);
		foreach TPRI.Tower.Blocks(Block, BlockIndex)
		{
			if(Block.GridLocation == GridLocation)
			{
				return Block;
			}
		}
	}
	*/
	return None;
}

function RestartPlayer(Controller aPlayer)
{
	Super.RestartPlayer(aPlayer);
	// aPlayer default state is PlayerWaiting
	// self default state is PendingMatch
	TowerPlayerController(aPlayer).GotoState('Master');

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
	DefaultPawnClass=class'Tower.TowerPawn'
	HUDType=class'Tower.TowerHUD'
}