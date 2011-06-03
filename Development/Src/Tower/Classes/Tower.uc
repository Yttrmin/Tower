/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends TowerFaction
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

function TowerBlock AddBlock(TowerBlock BlockArchetype, TowerBlock Parent,
	out Vector SpawnLocation, out IVector GridLocation)
{
	local TowerBlock NewBlock;
	local Vector AirSpawnLocation;
	local IVector AirGridLocation;
	NewBlock = BlockArchetype.AttachBlock(BlockArchetype, Parent, NodeTree, SpawnLocation, GridLocation, OwnerPRI);
	if(NewBlock.class != class'TowerBlockAir')
	{
		AirGridLocation = NewBlock.GridLocation + Vect(1,0,0);
		AirSpawnLocation.X = (AirGridLocation.X * 256);
		AirSpawnLocation.Y = (AirGridLocation.Y * 256);
		AirSpawnLocation.Z = (AirGridLocation.Z * 256) + 128;
		NewBlock.AttachBlock(TowerGame(WorldInfo.Game).GameMods[0].ModBlocks[5], NewBlock, NodeTree, AirSpawnLocation, AirGridLocation, OwnerPRI);
	}
	// Tell AI about this?
	return NewBlock;
}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller)
{
}

function bool RemoveBlock(TowerBlock Block)
{
	Block.RemoveBlock(Block, NodeTree);
	return true;
//	NodeTree.RemoveNode(Placeable);
}

function TowerBlock GetBlockFromLocationAndDirection(out IVector GridLocation, out IVector ParentDirection)
{
	local Actor Block;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation, VectorGridLocation;
	VectorGridLocation = ToVect(GridLocation);
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(VectorGridLocation);
	// The origin of blocks is on their bottom, so bump it up a bit so we're not on the edge.
	StartLocation.Z += 128;
	EndLocation.X = StartLocation.X + (ParentDirection.X * 512);
	EndLocation.Y = StartLocation.Y + (ParentDirection.Y * 512);
	EndLocation.Z = StartLocation.Z + (ParentDirection.Z * 512);
	//StartLocation.X += abs(ParentDirection.X * 128);
	//StartLocation.Y += abs(ParentDirection.Y * 128);
	//StartLocation.Z += abs(ParentDirection.Z * 128);
//	`log("Tracing From:"@StartLocation@"To:"@EndLocation@"ParentDirection:"@ParentDirection);
	Block = NodeTree.Root.Trace(HitLocation, HitNormal, EndLocation, StartLocation, TRUE);
//	`log(Block);
	return TowerBlock(Block);
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
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bStatic=False
	bNoDelete=False
}