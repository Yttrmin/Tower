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
	RootBlock = Root.Spawn(class'TowerAIObjective',,, Root.Location);
	RootBlock.Target = Root;
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