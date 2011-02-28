/**
TowerModInfo

Entry point for all mods. Lists all the classes it contains that are children of existing classes,
making it easily accessible to the main game. The only required class for a mod.
*/
class TowerModInfo extends ReplicationInfo
	ClassGroup(Tower)
	placeable; // Or make this placeable as well so it can all be done in UnrealEd?

var() const string ModName;
var() const string AuthorName;
var() const string Contact;
var() const string Description;
var() const string Version;

var() protectedwrite const array<class<TowerModule> > ModModules;

var() protectedwrite const array<TowerPlaceable> ModPlaceables;

var repnotify TowerModInfo NextMod;

var bool bLoaded;

replication
{
	if(bNetInitial)
		NextMod;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	`log("MOD LOADED OR SOMETHING SIMULATED?"@SELF);
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'NextMod')
	{
		TowerGameReplicationInfo(WorldInfo.GRI).AreModsLoaded();
	}
}

/** Called by TowerGame after all mods are loaded. */
event ModLoaded(const out array<String> ModList);

final function PreInitialize(int ModIndex)
{
	/*
	local int i;
	for(i = 0; i < ModBlockInfo.Length; i++)
	{
		ModBlockInfo[i].ModIndex = ModIndex;
		ModBlockInfo[i].ModBlockInfoIndex = i;
		`log("Modified ModBlockInfo:"@ModBlockInfo[i].ModIndex@ModBlockInfo[i].ModBlockInfoIndex@ModIndex@i);
	}
	*/
}

final function AddMod(TowerModInfo Mod)
{
	local TowerModInfo ModList;
	for(ModList = Self; ModList != None; ModList = ModList.NextMod)
	{
	}
	ModList.NextMod = Mod;
}

DefaultProperties
{
	ModName="My Mod Name"
	AuthorName="My Name"
	Contact="My Email"
	Description="My Description"
	Version="1.0"

	bAlwaysRelevant=TRUE
	// Example of adding your own block. MyTowerBlock must derive from TowerBlock.
//	ModBlocks.Add(class'MyTowerBlock')
}