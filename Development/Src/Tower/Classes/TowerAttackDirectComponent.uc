/**
TowerAttackDirectComponent

Just straight-up deals damage to all targets in range, performing no checks or anything.
Useful for things like flamethrowers, where you can assume that if a Targetable's in range, they can be damaged
without having to perform any traces or shoot any projectiles.
*/
class TowerAttackDirectComponent extends TowerAttackComponent;