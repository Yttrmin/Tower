/**
TowerModInfo

Entry point for all mods. Lists all the classes it contains that are children of existing classes,
making it easily accessible to the main game. The only required class for a mod.
*/
class TowerModInfo extends Info
	abstract;
 
var const string AuthorName;
var const string Contact;
var const string Description;
var const string Version;

/** Add your custom TowerBlocks to this array in DefaultProperties. */
var protected const array<class<TowerBlock> > ModBlocks;

var protected const array<class<TowerModule> > ModModules;

/** Called by TowerGame after all mods are loaded. */
event ModLoaded(const out array<String> ModList);

DefaultProperties
{
	AuthorName="My Name"
	Contact="My Email"
	Description="My Description"
	Version="1.0"
	// Example of adding your own block. MyTowerBlock must derive from TowerBlock.
//	ModBlocks.Add(class'MyTowerBlock')
}