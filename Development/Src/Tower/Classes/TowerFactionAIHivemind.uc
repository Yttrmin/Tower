class TowerFactionAIHivemind extends Object;

var array<PlaceableInfo> Placeables;
//@TODO - Doesn't handle multiplayer.
var TowerAIObjective RootBlock;

event Initialize()
{
	`log("HIVEMIND CREATED");
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

function SaveToDisk()
{
	if(class'Engine'.static.BasicSaveObject(self, "Hivemind_Store.bin", false, 0))
	{
		// Saving succeeded.
	}
	else
	{
		// Saving failed.
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
	}
}