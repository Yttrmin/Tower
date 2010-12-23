/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/
class TowerGame extends UTGame;

struct NetIDPRI
{
	var UniqueNetID PlayerNetID;
	var TowerPlayerReplicationInfo PRI;
};

var array<NetIDPRI> PlayerInfo;

enum Factions
{
	FA_Player
};

function AddTower(TowerPlayerController Player,  optional string TowerName="")
{
	TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower = Spawn(class'Tower', Player);
	//ServerAddBlock(TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower, XBlock, YBlock, ZBlock);
	if(TowerName != "")
	{
		SetTowerName(TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower, TowerName);
	}
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}

function AddBlock(Tower Tower, class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock)
{
	local vector SpawnLocation;
	SpawnLocation =  GridLocationToVector(XBlock, YBlock, ZBlock, BlockClass);
	// Pivot point is in middle, bump it up so we're not in the ground.
	SpawnLocation.Z += 128;
	if(CanAddBlock(XBlock, YBlock, ZBlock))
	{
		Tower.AddBlock(BlockClass, SpawnLocation);
		Broadcast(Tower, "Block added");
	}
	else
	{
		Broadcast(Tower, "Could not add block");
	}
}

function bool CanAddBlock(int XBlock, int YBlock, int ZBlock)
{
	return (IsGridLocationFree(XBlock, YBlock, ZBlock) && IsGridLocationOnGrid(XBlock, YBlock, ZBlock));
}

function Vector GridLocationToVector(int XBlock, int YBlock, int ZBlock, class<TowerBlock> BlockClass)
{
	local int MapBlockWidth, MapBlockHeight;
	local Vector NewBlockLocation;
	MapBlockHeight = TowerMapInfo(WorldInfo.GetMapInfo()).BlockHeight;
	MapBlockWidth = TowerMapInfo(WorldInfo.GetMapInfo()).BlockWidth;
	NewBlockLocation.X = (BlockClass.default.XSize / MapBlockWidth)*(XBlock * MapBlockWidth);
	NewBlockLocation.Y = (BlockClass.default.YSize / MapBlockWidth)*(YBlock * MapBlockWidth);;
	NewBlockLocation.Z = (BlockClass.default.ZSize / MapBlockHeight)*(ZBlock * MapBlockHeight);;
	return NewBlockLocation;
}

function bool IsGridLocationOnGrid(int XBlock, int YBlock, int ZBlock)
{
	return true;
}

function bool IsGridLocationFree(int XBlock, int YBlock, int ZBlock)
{
	return true;
}

function UTBot AddBot(optional string BotName, optional bool bUseTeamIndex, optional int TeamIndex){}

event PostBeginPlay()
{
	Super.PostBeginPlay();
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
	local NetIDPRI Info;
	Super.PostLogin(NewPlayer);
	Info.PlayerNetID = NewPlayer.PlayerReplicationInfo.UniqueID;
	Info.PRI = TowerPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
	PlayerInfo.AddItem(Info);
	AddTower(TowerPlayerController(NewPlayer));
}

function RestartPlayer(Controller aPlayer)
{
	`log("RESTARTED");
	`log(aPlayer.GetStateName());
	ScriptTrace();
	// aPlayer default state is PlayerWaiting
	// self default state is PendingMatch
	TowerPlayerController(aPlayer).GotoState('Master');
}

function AddInitialBots()
{
	local int AddCount;
	return;
	// add any bots immediately
	while (NeedPlayers() && AddBot() != None && AddCount < 16)
	{
		AddCount++;
	}
}

DefaultProperties
{
	MaxPlayersAllowed = 4
	PlayerControllerClass=class'Tower.TowerPlayerController'
	PlayerReplicationInfoClass=class'Tower.TowerPlayerReplicationInfo'
	GameReplicationInfoClass=class'Tower.TowerGameReplicationInfo'
	DefaultPawnClass=class'Tower.TowerPawn'
	bAutoNumBots = False
	DesiredPlayerCount = 1
}