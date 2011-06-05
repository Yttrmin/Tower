/**
TowerModInfo

Entry point for all mods. Lists all the classes it contains that are children of existing classes,
making it easily accessible to the main game. The only required class for a mod.
*/
class TowerModInfo extends ReplicationInfo
	ClassGroup(Tower)
	HideCategories(Display,Attachment,Physics,Advanced,Object)
	AutoExpandCategories(TowerModInfo)
	placeable;

var() privatewrite const string ModName;
var() privatewrite const string AuthorName;
var() privatewrite const string WebSite;
var() privatewrite const string Contact;
var() privatewrite const string Description;
var() privatewrite const string Version;

var() privatewrite const array<TowerBlock> ModBlocks;

var() privatewrite const array<TowerFactionAI> ModFactionAIs;

var repnotify TowerModInfo NextMod;

var deprecated bool bLoaded;

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
	for(ModList = Self; ModList != None; ModList = ModList.NextMod);
	ModList.NextMod = Mod;
}

//==============================================================================
// Save/Load events.
// Note that custom blocks are saved and loaded by the game, there's no need to save/load them yourself.

/** Called by TowerGame during a regular save. */
event GameSaved();

/** Called by TowerGame during a regular load. */
event GameLoaded();

/** Called by TowerGame during a quick save. */
event GameQuickSaved();

/** Called by TowerGame during a quick load. */
event GameQuickLoaded();
//==============================================================================

DefaultProperties
{
	ModName="My Mod Name"
	AuthorName="My Name"
	WebSite="My Website"
	Contact="My Email"
	Description="My Description"
	Version="1.0"

	bAlwaysRelevant=TRUE
}