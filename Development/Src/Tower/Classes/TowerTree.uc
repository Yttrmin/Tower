class TowerTree extends Object
	dependson(TowerBlock);

var protectedwrite TowerBlock Root;

final function RemoveNode(TowerBlock NodeToRemove, optional bool bDeleteChildren)
{
	// Try to find parent for children, if not, they fall onto another one.
	local TowerBlock Node;
	local array<TowerBlock> RemovedNodeChildren;
	RemovedNodeChildren = NodeToRemove.NextNodes;
	`log("Removing node:"@NodeToRemove$"...");
	// If we don't destroy the node before finding parents for its children, they'll end up tracing
	// into their to-be-destroyed parent, adding themselves back to their parent, getting told to
	// find a new parent, and so forth, an infinite loop.
	NodeToRemove.Destroy();
	foreach RemovedNodeChildren(Node)
	{
		`log("Getting children new parents...");
		if(bDeleteChildren)
		{
			RemoveNode(Node);
		}
		else
		{
			`log("Finding new parent for"@Node$"...");
			FindNewParent(Node);
		}
	}
	`log("Done. Destroying node:"@NodeToRemove);
}

final function bool AddNode(TowerBlock NewNode, optional TowerBlock ParentNode)
{
	if(ParentNode == None)
	{
		if(Root == None)
		{
			Root = NewNode;
			return true;
		}
		else
		{
			`Log("Tried to add a new node with no parent when there's already a root node!"@NewNode@"at grid location:"@NewNode.GridLocation);
			return false;
		}
	}
	ParentNode.NextNodes.AddItem(NewNode);
	NewNode.PreviousNode = ParentNode;
	return true;
}

final function TowerBlock GetRootNode()
{
	return Root;
}

//HasSupport

/** Tries to find any nodes physically adjacent to the given one. */
final function bool FindNewParent(TowerBlock Node)
{
	local TowerBlock Block;
	local array<TowerBlock> SupportNodes;
	`log(Node@"Finding parent for node.");
	GetFullSupport(Node, SupportNodes);
	`log("Node has"@SupportNodes.length@"potential blocks for support:");
	foreach SupportNodes(Block)
	{
		`log(Block);
	}
	foreach SupportNodes(Block)
	{
		if(TraceNodeToRoot(Block))
		{
			`log("Found path to root, parenting with node.");
			AddNode(Node, Block);
			return true;
		}
	}
	`log("No parents available,"@Node@"is an orphan. Handle this.");
	return false;
}

final function bool TraceNodeToRoot(TowerBlock Node)
{
	return true;
}

/** Populates given array with all nodes that can possibly support it. */
final function GetFullSupport(TowerBlock NodeToCheck, out array<TowerBlock> SupportNodes)
{
	local Vector HitLocation, HitNormal;
	local Vector TraceEnd;
	local TowerBlock HitBlock;

	TraceEnd = NodeToCheck.Location;
	TraceEnd.X += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.X -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Y += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Y -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Z += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Z -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

}