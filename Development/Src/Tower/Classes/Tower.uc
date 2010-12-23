/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

/** Replicated to clients so they know whether to add or remove this block to the tower's
block array. */
enum RepCode
{
	/** This block was added to the world. */
	RC_Add,
	/** This block was deleted from the world. */
	RC_Delete
};

struct BlockRep
{
	var TowerBlock Block;
	var RepCode Code;
	var int ArrayPos;
};

var array<TowerBlock> Blocks;
var repnotify BlockRep ReplicatedBlock;
var string TowerName;

replication
{
	if(bNetDirty)
		TowerName, ReplicatedBlock;
}

simulated event ReplicatedEvent(name VarName)
{
	switch(VarName)
	{
	case 'ReplicatedBlock':
		AddReplicatedBlock();
		return;
	}
}

simulated function AddReplicatedBlock()
{

}

function AddBlock(class<TowerBlock> BlockClass, Vector SpawnLocation)
{
	Blocks.AddItem(Spawn(BlockClass, self,, SpawnLocation));
}

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
}