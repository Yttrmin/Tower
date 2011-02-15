class TowerMapInfo extends MapInfo;

/** Notifies TowerBlockRoot when enemies and projectiles touch this. This will be the absolute
maximum range of all modules, so this should probably take up most of the level. */
var() const Volume RadarVolume;
/** The SceneCaptureActor used to render blocks to a texture when previewing them in the HUD. */
var() const SceneCaptureActor BuildPreviewSceneCaptureActor;
var() const array<PointLightToggleable> PreviewLights;
var() const DynamicSMActor PreviewBlock;

var() const int XBlocks;
var() const int YBlocks;
var() const int ZBlocks;

// Move me to TowerGame thanks.
var() const editconst int BlockWidth;
var() const editconst int BlockHeight;

function ActivateHUDPreview()
{
	local PointLightToggleable Light;
	BuildPreviewSceneCaptureActor.SceneCapture.SetEnabled(TRUE);
	foreach PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(TRUE);
	}
}

function DeactivateHUDPreview()
{
	local PointLightToggleable Light;
	BuildPreviewSceneCaptureActor.SceneCapture.SetEnabled(FALSE);
	foreach PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(FALSE);
	}
}

simulated function SetPreviewBlock(out BlockInfo Block)
{
	PreviewBlock.StaticMeshComponent.SetStaticMesh(Block.BlockMesh);
	PreviewBlock.StaticMeshComponent.SetMaterial(0, Block.BlockMaterial);
}

DefaultProperties
{
	// 256 probably best, could fit several people in.
	BlockWidth = 256
	BlockHeight = 256
}