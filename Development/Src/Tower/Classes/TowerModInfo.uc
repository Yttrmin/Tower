/**
TowerModInfo

Entry point for all mods. Lists all the classes it contains that are children of existing classes,
making it easily accessible to the main game. The only required class for a mod.
*/
class TowerModInfo extends ReplicationInfo
	ClassGroup(Tower)
	HideCategories(Display,Attachment,Physics,Advanced,Object)
	AutoExpandCategories(TowerModInfo)
	placeable; // Or make this placeable as well so it can all be done in UnrealEd?

var() const string ModName;
var() const string AuthorName;
var() const string Contact;
var() const string Description;
var() const string Version;

var() protectedwrite const array<TowerBlock> ModBlocks;

var() protectedwrite const array<TowerFactionAI> ModFactionAIs;

var repnotify TowerModInfo NextMod;

var bool bLoaded;
var bool bTest;

replication
{
	if(bNetInitial)
		NextMod;
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

event GameSaved();

event GameLoaded();

event GameQuickSaved();

event GameQuickLoaded();

function Test();

DefaultProperties
{
	ModName="My Mod Name"
	AuthorName="My Name"
	Contact="My Email"
	Description="My Description"
	Version="1.0"

	bAlwaysRelevant=TRUE
}