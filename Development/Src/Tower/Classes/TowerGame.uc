/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends FrameworkGame;

enum Factions
{
	F_Debug,
	// F_Player represents all humans players in the game since it's co-op only.
	F_Player
};

var array<Tower> PlayerTowers;
var array<TowerFactionAI> FactionAIs;
var array<TowerSpawnPoint> InfantryPoints, ProjectilePoints, VehiclePoints;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	PopulateSpawnPointArrays();
	AddFactionAIs();
//	StartNextRound();
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

exec function SkipRound()
{
	StartNextRound();
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
	StartCoolDown();
}

function AddTower(TowerPlayerController Player,  optional string TowerName="")
{
	local TowerPlayerReplicationInfo TPRI;
	TPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	//@BUG
	// For whatever reason PlayerController won't collide with children, so we're breaking
	// the ownership chain right here. There's probably a flag for child collision but
	// I can't find it.
	TPRI.Tower = Spawn(class'Tower');
	TPRI.Tower.OwnerPRI = TPRI;
	// Need to make this dependent on player count in future.
	//@FIXME - This can be done a bit more cleanly and safely.
	AddBlock(TPRI.Tower, class'TowerBlockDebug', 8*(NumPlayers-1), 0, 0, true);
	if(TowerName != "")
	{
		SetTowerName(TPRI.Tower, TowerName);
	}
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}

function AddBlock(Tower Tower, class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock,
	optional bool bRootBlock = false)
{
	local vector SpawnLocation;
	SpawnLocation =  GridLocationToVector(XBlock, YBlock, ZBlock, BlockClass);
	// Pivot point is in middle, bump it up so we're not in the ground.
	SpawnLocation.Z += 128;
	if(CanAddBlock(XBlock, YBlock, ZBlock))
	{
		Tower.AddBlock(BlockClass, SpawnLocation, XBlock, YBlock, ZBlock, bRootBlock);
		Broadcast(Tower, "Block added");
	}
	else
	{
		Broadcast(Tower, "Could not add block");
	}
}

/** Removes block from a given grid location. Can't be removed if bRootBlock. Returns TRUE if removed.*/
function bool RemoveBlock(Tower CallingTower, int XBlock, int YBlock, int ZBlock)
{
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
}

function bool CanAddBlock(int XBlock, int YBlock, int ZBlock)
{
	return (IsGridLocationFree(XBlock, YBlock, ZBlock) && IsGridLocationOnGrid(XBlock, YBlock, ZBlock));
}

function Vector GridLocationToVector(int XBlock, int YBlock, int ZBlock, optional class<TowerBlock> BlockClass)
{
	local int MapBlockWidth, MapBlockHeight;
	local Vector NewBlockLocation;
	MapBlockHeight = TowerMapInfo(WorldInfo.GetMapInfo()).BlockHeight;
	MapBlockWidth = TowerMapInfo(WorldInfo.GetMapInfo()).BlockWidth;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (XBlock * MapBlockWidth);
	NewBlockLocation.Y = (YBlock * MapBlockWidth);
	// Z is the very bottom of the block.
	NewBlockLocation.Z = (ZBlock * MapBlockHeight);
	return NewBlockLocation;
}

function bool IsGridLocationOnGrid(int XBlock, int YBlock, int ZBlock)
{
	local int MapXBlocks; 
	local int MapYBlocks; 
	local int MapZBlocks;
	MapXBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).XBlocks;
	MapYBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).YBlocks;
	MapZBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).ZBlocks;
	if((XBlock <= MapXBlocks/2 && XBlock >= -MapXBlocks/2) && 
		(YBlock <= MapYBlocks/2 && YBlock >= -MapYBlocks/2) &&
		(ZBlock <= MapZBlocks/2 && ZBlock >= -MapZBlocks/2))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function bool IsGridLocationFree(int XBlock, int YBlock, int ZBlock)
{
	return true;
}

function TowerBlock GetBlockFromGrid(int XBlock, int YBlock, int ZBlock, out int BlockIndex)
{
	//@BUG - Blocks don't like to be traced.
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
	return None;
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
	AddTower(TowerPlayerController(NewPlayer));
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