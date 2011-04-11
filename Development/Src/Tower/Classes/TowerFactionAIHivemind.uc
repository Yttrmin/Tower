class TowerFactionAIHivemind extends Object;

var array<PlaceableInfo> Placeables;

event Initialize()
{
	`log("HIVEMIND CREATED");
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