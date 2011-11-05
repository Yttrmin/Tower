/**
TowerFactionAIHivemind

A class to store and manipulate information useful for all TowerFactionAIs.
This class is ticked during asynchronous work, so any sort of collision, spawning, location, etc related function
will fail!
*/
class TowerFactionAIHivemind extends Info
	config(Tower);


struct BlockUsage
{
	var bool bStructural;
	var bool bGunHitscan;
	var bool bGunProjectile;
	var bool bShield;
	var bool bAntiInfantry;
	var bool bAntiVehicle;
	var bool bAntiProjectile;
};

struct AIBlockInfo
{
	var TowerBlock BlockArchetype;
	var BlockUsage Flags;
};
/*
struct BlockNode
{
	var int Cost;
};

struct BlockInfo
{
	var TowerBlock Block;
	var int Cost;
};

struct TowerBlockAir extends BlockNode
{
	var IVector GridLocation;
};
*/

//@TODO - Transient? Will it still be saved to config?
var private config bool bSaveToDisk;

var array<AIBlockInfo> Blocks;
//@TODO - Doesn't handle multiplayer.
var TowerAIObjective RootBlock;

/** Allows Actors to register for a TG_DuringAsyncWork. Useful for when an AI thinks. */
var privatewrite array<delegate<AsyncTick> > ToTick;

delegate AsyncTick(float DeltaTime);

event Tick(float DeltaTime)
{
	local delegate<AsyncTick> TickDelegate;
	Super.Tick(DeltaTime);
	foreach ToTick(TickDelegate)
	{
		TickDelegate(DeltaTime);
	}
}

event Initialize()
{
	
}

function RegisterForAsyncTick(delegate<AsyncTick> TickDelegate)
{
	ToTick.AddItem(TickDelegate);
	SetTickIsDisabled(false);
}

function UnRegisterForAsyncTick(delegate<AsyncTick> TickDelegate)
{
	ToTick.RemoveItem(TickDelegate);
	if(ToTick.Length == 0)
	{
		SetTickIsDisabled(true);
	}
}

event OnRootBlockSpawn(TowerBlockRoot Root)
{
	local Vector NewLocation;
	NewLocation = Root.Location;
	NewLocation.X = -400;
	NewLocation.Z = 3;
	NewLocation.Y = 1000;
	//@TODO - Spawn this in the block, create points for people to actually run to.
	RootBlock = Root.Spawn(class'TowerAIObjective',,, NewLocation);
	RootBlock.SetTarget(Root);
}

event OnBlockSpawn(TowerBlock NewBlock)
{
}

function SaveToDisk()
{
	if(class'Engine'.static.BasicSaveObject(self, "Hivemind_Store.bin", false, 0))
	{
		// Saving succeeded.
	}
	else
	{
		// Saving failed.
		`warn("Failed to save Hivemind data!",,'Hivemind');
	}
}

function LoadFromDisk()
{
	if(class'Engine'.static.BasicLoadObject(self, "Hivemind_Store.bin", false, 0))
	{
		// Loading succeeded.
	}
	else
	{
		// Loading failed.
		`warn("Failed to load Hivemind data!",,'Hivemind');
	}
}

DefaultProperties
{
	TickGroup=TG_DuringAsyncWork
	RemoteRole=ROLE_None
}