class TowerGFxMinimapHUD extends GFxMoviePlayer;

/** If true, let weapons draw their crosshairs instead of using GFx crosshair */
var bool bDrawWeaponCrosshairs;
var GFxMinimap Minimap;

function AddMessage(string type, string msg);
function AddDeathMessage(PlayerReplicationInfo Killer, PlayerReplicationInfo Killed, class<UTDamageType> Dmg);
function ShowMultiKill(int n, string msg);
function TickHud(float DeltaTime);
function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType);
function ToggleCrosshair(bool bToggle);
function MinimapZoomOut();
function MinimapZoomIn();
function SetCenterText(string text);