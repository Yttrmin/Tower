/**
TowerModInfo

Entry point for all mods. Lists all the classes it contains that are children of existing classes,
making it easily accessible to the main game. The only required class for a mod.
*/
class TowerModInfo extends ReplicationInfo
	abstract;

var const string ModName;
var const string AuthorName;
var const string Contact;
var const string Description;
var const string Version;

// Don't expose material, instead expose a texture that can be set in parameters?
// Material has more control, and the processes are pretty much identical...
// But just texture means more consistency and less breaking.

var protectedwrite array<BlockInfo> ModBlockInfo;

/** Add your custom TowerBlocks to this array in DefaultProperties. */
var deprecated protectedwrite const array<class<TowerBlock> > ModBlocks;

var protectedwrite const array<class<TowerModule> > ModModules;

/** Called by TowerGame after all mods are loaded. */
event ModLoaded(const out array<String> ModList);

final function PreInitialize(int ModIndex)
{
	local int i;
	for(i = 0; i < ModBlockInfo.Length; i++)
	{
		ModBlockInfo[i].ModIndex = ModIndex;
		ModBlockInfo[i].ModBlockInfoIndex = i;
		`log("Modified ModBlockInfo:"@ModBlockInfo[i].ModIndex@ModBlockInfo[i].ModBlockInfoIndex@ModIndex@i);
	}
}

DefaultProperties
{
	ModName="My Mod Name"
	AuthorName="My Name"
	Contact="My Email"
	Description="My Description"
	Version="1.0"
	// Example of adding your own block. MyTowerBlock must derive from TowerBlock.
//	ModBlocks.Add(class'MyTowerBlock')
}