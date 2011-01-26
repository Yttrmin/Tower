/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

var protectedwrite TowerTree NodeTree;

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

function AddBlock(class<TowerBlock> BlockClass, TowerBlock ParentBlock, Vector SpawnLocation, 
	int XBlock, int YBlock, int ZBlock, optional bool bRootBlock = false)
{
	local TowerBlock Block;
	local Vector GridLocation;
	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	Block = Spawn(BlockClass, self,, SpawnLocation);
	Block.Initialize(GridLocation, OwnerPRI, bRootBlock);
	NodeTree.AddNode(Block, ParentBlock);
	/**
//	Block.Tower = self;
	Blocks.AddItem(Block);
	*/
}

function bool RemoveBlock(TowerBlock Block)
{
	NodeTree.RemoveNode(Block);
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