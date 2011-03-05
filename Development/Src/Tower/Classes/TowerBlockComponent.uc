/** 
TowerBlockComponent

Potential class for exploiting Component's speed versus Actor's. Instead of having every block be Actor-derived, they may
instead be TowerBlockComponents attached to a TowerBlock, such as the root. In the case of needing to make a block fall, the root
block of that branch would be made into a TowerBlock, and its children would be attached to it. 
We'll see how this plays out in the future! 
*/
class TowerBlockComponent extends ActorComponent;