class TowerPlayerReplicationInfo extends PlayerReplicationInfo
	config(Tower);

struct ModOption
{
	var String ModName;
	var bool bEnabled;
	var bool bRunForServer;
};

var Tower Tower;
/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var config LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it.
Setting this to 1 means no bloom assuming HighlightColor has no colors over 1.*/
var config byte HighlightFactor;

/** If TRUE, ModLoaded() in TowerModInfo contains an array of mod names, if FALSE, it contains an
empty array.*/
var protected globalconfig bool bShareModNamesWithMods;
var protected globalconfig bool bDebugMods;
/** Holds the PackageName.ClassName of TowerModInfos to load in the order given. */
var protectedwrite globalconfig array<String> ModClasses;

// Maybe this should go to TowerPlayerController (WHO KNOWS)
var protectedwrite array<TowerModInfo> Mods;
var protectedwrite array<ModOption> ModOptions;
var protectedwrite array<BlockInfo> PlaceableBlocks;

replication
{
	if(bNetDirty)
		Tower, HighlightColor;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	DeterminePlaceableBlocks();
//	TowerHUD(TowerPlayerController(Owner).myHUD).SetPlaceablesList(PlaceableBlocks);
	SetHighlightColor(HighlightColor);
	RequestUpdatedTime();
}

simulated function DeterminePlaceableBlocks()
{
	local String Mod;
	local array<String> ModsToLoad;
	local TowerModInfo ModInfo;
	local BlockInfo Block;
	ModsToLoad = SplitString(TowerGameReplicationInfo(WorldInfo.GRI).ServerMods, ";");
	`log("ServerMods:"@TowerGameReplicationInfo(WorldInfo.GRI).ServerMods);
	foreach ModsToLoad(Mod)
	{
		LoadMod(Mod);
	}
	foreach Mods(ModInfo)
		{
			`log("Checking if"@ModInfo.ModName@"equals"@Mod);
			if(ModInfo.ModName == Mod)
			{
				foreach ModInfo.ModBlockInfo(Block)
				{
					`log("Adding placeable block:"@Block.DisplayName);
					PlaceableBlocks.AddItem(Block);
				}
				break;
			}
		}
}

simulated function LoadMod(String ModName)
{
	local class<TowerModInfo> ModInfo;
	ModName $= ".TowerModInfo_"$ModName;
	ModInfo = class<TowerModInfo>(DynamicLoadObject(ModName,class'class',false));
	Mods.AddItem(Spawn(ModInfo));
}

reliable server function SetHighlightColor(LinearColor NewColor)
{
	NewColor.R *= HighlightFactor;
	NewColor.G *= HighlightFactor;
	NewColor.B *= HighlightFactor;
	HighlightColor = NewColor;
}

reliable server function RequestUpdatedTime()
{
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = 
		TowerGame(WorldInfo.Game).GetRemainingTime();
	`log("UPDATED TIME! NEW VALUE:"@TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime);
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}