/**
TowerModInfo

Entry point for all mods. Essentially serves as an index of everything in this mod,
making the content easily accessible to the game. The only required class for a mod.
If you're only adding custom blocks or AI, this should not have to be subclassed.
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
var() privatewrite deprecated const string Version;

var() privatewrite const byte MajorVersion;
var() privatewrite const byte MinorVersion;

var() privatewrite const array<TowerBlock> ModBlocks;

var() privatewrite const array<TowerFactionAI> ModFactionAIs;

var privatewrite repnotify TowerModInfo NextMod;

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
		TowerGameReplicationInfo(WorldInfo.GRI).OnModReplicated(NextMod);
	}
}

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

/** Adds a mod to the end of the linked list regardless of this mod's position in it. */
final function AddMod(TowerModInfo Mod)
{
	if(NextMod == None)
	{
		NextMod = Mod;
	}
	else
	{
		NextMod.AddMod(Mod);
	}
}

/** Should only be called on the RootMod. Returns the number of mods in the linked list. */
final simulated function int GetModCount(optional int Count=0)
{
	Count++;
	if(NextMod != None)
	{
		return NextMod.GetModCount(Count);
	}
	else
	{
		return Count;
	}
}

/** Called after mod is loaded and ready for use. */
simulated event Initialize()
{
	`log(ModName@"has been loaded.");
	NextMod.Initialize();
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
	WebSite="www.MyWebsite.com"
	Contact="MyEmail@email.com"
	Description="My Description"
	Version="1.0"

	bAlwaysRelevant=TRUE
}