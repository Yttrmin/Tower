/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

var protectedwrite TowerTree NodeTree;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever!*/
var() private array<TowerBlock> DebugBlocks;

var() string TowerName;
var() TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	NodeTree = new class'TowerTree';
}

function TowerBlock AddBlock(class<TowerBlock> BlockClass, TowerBlock ParentBlock, 
	Vector SpawnLocation, int XBlock, int YBlock, int ZBlock, optional bool bRootBlock = false)
{
	local TowerBlock Block;
	local Vector GridLocation, ParentDirection;
	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	if(ParentBlock != None)
	{
		ParentDirection = Normal(ParentBlock.Location - SpawnLocation);
		`log("ParentDirection:"@ParentDirection);
	}
	Block = Spawn(BlockClass, self,, SpawnLocation,,,TRUE);
	Block.Initialize(GridLocation, ParentDirection, OwnerPRI, bRootBlock);
	NodeTree.AddNode(Block, ParentBlock);
	//@DEBUG
	if(OwnerPRI.Tower.NodeTree.bDebugDrawHierarchy)
	{
		DebugBlocks.AddItem(Block);
		DrawDebugString(Vect(-128,-128,0), Block.Name, Block);
	}
	return Block;
	//@DEBUG
	/**
//	Block.Tower = self;
	Blocks.AddItem(Block);
	*/
}

function TowerBlock GetBlockFromLocationDirection(out Vector GridLocation, out Vector ParentDirection)
{
	local Actor Block;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation;
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(GridLocation.X, GridLocation.Y,
		GridLocation.Z);
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
	if(Block.PreviousNode != None)
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