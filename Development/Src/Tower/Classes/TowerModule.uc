class TowerModule extends ActorComponent
	abstract;

/** User-friendly name. Used for things like the build menu. */
var String DisplayName;

event Initialize();

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
}