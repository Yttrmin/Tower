class TowerGameReplicationInfo extends GameReplicationInfo;

var byte Phase;
var repnotify byte Round;

var protectedwrite bool bRoundInProgress;

var int EnemyCount;
var int MaxEnemyCount;

/** Placeable blocks available to the player. Retrieved from PlaceableList. */
var array<class<TowerBlock> > PlaceableBlocks;
/** Placeable modules available to the player. Retrieved from PlaceableList. */
var array<class<TowerModule> > PlaceableModules;

var repnotify float ReplicatedTime;

// Tower(TowerBlockDebug;TowerBlockRoot;)MyMod(TowerBlock_MyBlock;)
var repnotify String PlaceableString;
var repnotify String ServerMods;

replication
{
	if(bNetDirty)
		Phase, Round, EnemyCount, MaxEnemyCount, ReplicatedTime;
	if(bNetInitial)
		PlaceableString, ServerMods;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	CreatePlaceableString();
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'Round')
	{
		UpdateRoundCount();
	}
	else if(VarName == 'ReplicatedTime')
	{
		SetGameTimer();
	}
	else if(VarName == 'PlaceableString')
	{
		ParsePlaceableString();
	}
}

simulated function UpdateRoundCount()
{
	TowerHUD(GetPlayerController().myHUD).HUDMovie.SetRoundNumber(Round);
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

/** Called whenever ReplicatedTime is replicated for clients, when rounds/cool-downs start
for servers. Updates the player's HUD to display the proper time. */
simulated event SetGameTimer()
{
	TowerHUD(GetPlayerController().myHUD).HUDMovie.SetRoundTime(ReplicatedTime);
}

/** Called by TowerGame when cool-down period ends. */
event NextRound()
{
	bRoundInProgress = TRUE;
	Round++;
	UpdateRoundCount();
	// Completely arbitrary at the moment.
	MaxEnemyCount = Round*20;
}

event EndRound()
{
	bRoundInProgress = FALSE;
}

function CreatePlaceableString()
{
	local class<TowerBlock> BlockClass;
	local class<TowerModule> ModuleClass;
	local TowerModInfo ModInfo;
	/*
	foreach TowerGame(WorldInfo.Game).Mods(ModInfo)
	{
		// Block.class.outer$"."$Block.class
		PlaceableString $= ModInfo.class.outer$"(";
		foreach ModInfo.ModBlocks(BlockClass)
		{
			PlaceableString $= BlockClass$";";
		}
		foreach ModInfo.ModModules(ModuleClass)
		{
			PlaceableString $= ModuleClass$";";
		}
		PlaceableString $= ")";
	}
	*/
	ParsePlaceableString();
}

simulated function ParsePlaceableString()
{

}