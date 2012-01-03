/**
TowerModInfo

Entry point for all mods. Essentially serves as an index of everything in this mod,
making the content easily accessible to the game. The only required class for a mod.
If you're only adding custom blocks or AI, this should not have to be subclassed.
*/
class TowerModInfo extends Object
	ClassGroup(Tower)
	HideCategories(Display,Attachment,Physics,Advanced,Object)
	AutoExpandCategories(TowerModInfo)
	placeable;

/** The human-intended name of the mod. Should only be used to display a mod identifier to a user, not for comparisons.
Is absolutely NOT GUARANTEED to be unique or safe to use in a mod list when joining a server. 
For such purposes use GetSafeName(). */
var() privatewrite const string ModName<DisplayName="Mod Name">;
var() privatewrite const string AuthorName;
var() privatewrite const string WebSite;
var() privatewrite const string Contact;
var() privatewrite const string Description;
var() privatewrite const int Version;

var() privatewrite const deprecated byte MajorVersion;
var() privatewrite const deprecated byte MinorVersion;

var() privatewrite const array<TowerBlock> ModBlocks;

var() privatewrite const array<TowerFactionAI> ModFactionAIs;

//@TODO - Does this need to be an array, or should each mod just have one?
var() privatewrite const array<TowerMusicList> ModMusicLists;

var privatewrite TowerModInfo NextMod;

/** Client-only variable. Used to avoid race conditions between (believe it or not) ReplicatedEvent and NextMod being valid... */
var bool bLoaded;

/*
simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'NextMod')
	{
		`log(ModName@"has its NextMod replicated,"@NextMod.ModName$"!");
		TowerGameReplicationInfo(WorldInfo.GRI).OnModReplicated(NextMod);
	}
}
*/

/** Called before Initialize, sets important values for TowerBlocks that every mod needs done. */
final function PreInitialize(int ModIndex)
{
	local int i;
	for(i = 0; i < ModBlocks.Length; i++)
	{
		if(ModBlocks[i].PurchasableComponent != None)
		{
			ModBlocks[i].PurchasableComponent.CalculateCost(1);
		}
		ModBlocks[i].ModIndex = ModIndex;
		ModBlocks[i].ModBlockIndex = i;
	}
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

/** Only call on RootMod! Returns the number of mods in the linked list. */
final simulated function int GetModCount(optional int InternalCount=0)
{
	InternalCount++;
	if(NextMod != None)
	{
		return NextMod.GetModCount(InternalCount);
	}
	else
	{
		return InternalCount;
	}
	/*
	Count++;
	if(NextMod != None && (Role == Role_Authority || NextMod.bLoaded))
	{
		`log(ModName@"Current ModCount is"@Count@"and we have a NextMod"@NextMod.ModName);
		return NextMod.GetModCount(Count);
	}
	else
	{
		`log(ModName@"Current ModCount is"@Count@"and we have no NextMod. Returning.");
		return Count;
	}
	*/
}

/** Counting through all mods' ModBlocks, returns the Index block.
No consideration is made based on whether the block is bAddToBuildList or not. 
ReservedCurrentCount is used internally by the function, don't pass anything in. */
final function TowerBlock FindBlockArchetypeByIndex(int Index, optional int ReservedCurrentCount=0)
{
	if((ModBlocks.Length + ReservedCurrentCount) <= Index)
	{
		if(NextMod != None)
		{
			return NextMod.FindBlockArchetypeByIndex(Index, ReservedCurrentCount + ModBlocks.Length);
		}
		else
		{
			return None;
		}
	}
	else
	{
		return ModBlocks[Index - ReservedCurrentCount];
	}
}

final function String GetList(bool bIncludeVersion)
{
	return GetSafeName(bIncludeVersion)
		$(NextMod != None ? class'TowerGameBase'.const.MOD_DIVIDER$NextMod.GetList(bIncludeVersion) : "");
}

/** Returns a name that can be safely transferred over a URL. */
final function String GetSafeName(bool bIncludeVersion)
{
	/** Returns the package name (required by engine to be unique and have no weird characters), and optionally
			the version as well after a VERSION_DIVIDER. */
	return ObjectArchetype.GetPackageName()$
		(bIncludeVersion ? class'TowerGameBase'.const.VERSION_DIVIDER$Version : "");
}

final function TowerModInfo FindModBySafeName(out string SafeNameNoVersion)
{
	if(GetSafeName(false) == SafeNameNoVersion)
	{
		return self;
	}
	else if(NextMod != None)
	{
		return NextMod.FindModBySafeName(SafeNameNoVersion);
	}
	else
	{
		return None;
	}
}

final function GetAllMods(out array<TowerModInfo> OutMods)
{
	OutMods.AddItem(self);
	if(NextMod != None)
	{
		NextMod.GetAllMods(OutMods);
	}
	return;
}

/** Only call on RootMod! Returns the index of the given mod, -1 if the mod isn't in the linked list. */
final function int GetModIndex(TowerModInfo Mod, optional int Index=0)
{
	if(self == Mod)
	{
		return Index;
	}
	else if(NextMod != None)
	{
		Index++;
		return NextMod.GetModIndex(Mod, Index);
	}
	else if(NextMod == None)
	{
		return -1;
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
// Please be nice and call these functions for NextMod!

/** Called by TowerGame during a regular save. */
event GameSaved();

/** Called by TowerGame during a regular load. FileName does not contain the full path or extension. */
event GameLoaded(const out string FileName)
{
	if(NextMod != None)
	{
		NextMod.GameLoaded(FileName);
	}
}

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
	Version=-1
}