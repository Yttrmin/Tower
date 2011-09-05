class TowerDecalManager extends DecalManager;

//@TODO - Copied from UTGame, enable for split screen?
function bool CanSpawnDecals()
{
	return (!class'Engine'.static.IsSplitScreen() && Super.CanSpawnDecals());
}

defaultproperties
{
	DecalDepthBias=-0.00012
}