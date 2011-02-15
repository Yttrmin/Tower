class TowerModule extends ActorComponent
	abstract;

struct ModuleInfo
{
	var String DisplayName;
	var class<TowerModule> BaseClass;
};

/** User-friendly name. Used for things like the build menu. */
var String DisplayName;

event Initialize();

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
}