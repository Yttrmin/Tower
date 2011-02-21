class TowerModule extends ActorComponent
	HideCategories(Object)
	implements(TowerPlaceable)
	ClassGroup(Tower)
	abstract;

struct ModuleInfo
{
	var String DisplayName;
	var class<TowerModule> BaseClass;
};

/** User-friendly name. Used for things like the build menu. */
var() const String DisplayName;
var() const bool bAddToPlaceablesList;

event Initialize();

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToPlaceablesList=TRUE
}