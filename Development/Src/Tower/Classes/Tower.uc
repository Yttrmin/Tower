/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor
	dependson(TowerBlock);

var TowerTree NodeTree;
var TowerBlockRoot Root;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever!*/
var() private array<TowerBlock> DebugBlocks;

var() string TowerName;
var() repnotify TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
	if(bNetInitial)
		Root;
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	TowerGameReplicationInfo(WorldInfo.GRI).AreModsLoaded();
	AddTree();
}

reliable server function AddTree()
{
	NodeTree = new class'TowerTree';
}

function TowerPlaceable AddPlaceable(TowerPlaceable Placeable, TowerBlock Parent,
	out Vector SpawnLocation, out Vector GridLocation)
{
	local TowerPlaceable NewPlaceable;
	NewPlaceable = Placeable.AttachPlaceable(Placeable, Parent, NodeTree, SpawnLocation, GridLocation, OwnerPRI);
	if(TowerBlock(NewPlaceable) != None && NewPlaceable.GetGridLocation().Z == 0)
	{
		TowerGame(WorldInfo.Game).CrowdSpawner.BlockSpawned(TowerBlock(NewPlaceable));
	}
	return NewPlaceable;
}

function bool RemovePlaceable(TowerPlaceable Placeable)
{
	Placeable.RemovePlaceable(Placeable, NodeTree);
	return true;
//	NodeTree.RemoveNode(Placeable);
}

function TowerBlock GetBlockFromLocationAndDirection(out Vector GridLocation, out Vector ParentDirection)
{
	local Actor Block;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation;
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(GridLocation);
	// The origin of blocks is on their bottom, so bump it up a bit so we're not on the edge.
	StartLocation.Z += 128;
	EndLocation.X = StartLocation.X + (ParentDirection.X * 512);
	EndLocation.Y = StartLocation.Y + (ParentDirection.Y * 512);
	EndLocation.Z = StartLocation.Z + (ParentDirection.Z * 512);
	//StartLocation.X += abs(ParentDirection.X * 128);
	//StartLocation.Y += abs(ParentDirection.Y * 128);
	//StartLocation.Z += abs(ParentDirection.Z * 128);
	`log("Tracing From:"@StartLocation@"To:"@EndLocation@"ParentDirection:"@ParentDirection);
	Block = NodeTree.Root.Trace(HitLocation, HitNormal, EndLocation, StartLocation, TRUE);
	`log(Block);
	return TowerBlock(Block);
}

function bool RemoveBlock(TowerBlock Block)
{
	local TowerBlock IterateBlock;
	DebugBlocks.RemoveItem(Block);
	NodeTree.RemoveNode(Block);
	//@DEBUG
	FlushDebugStrings();
	foreach DebugBlocks(IterateBlock)
	{
		DrawDebugString(Vect(-128,-128,0), IterateBlock.Name, IterateBlock);
	}
	//@DEBUG
	return true;
}

function bool CheckForParent(TowerBlock Block)
{
	if(Block.GetParent() != None)
	{
		// You already have a parent.
		return true;
	}
	return NodeTree.FindNewParent(Block);
}

function CheckBlockSupport()
{
	// Toggling between PHYS_None and PHYS_RigidBody is not a solution at all, the physics simulation keeps going.
}

function FindBlock()
{

}

DefaultProperties
{
	bAlwaysRelevant = true;
	RemoteRole=ROLE_SimulatedProxy
}