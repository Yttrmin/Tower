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

var bool bRootBlockSet;

// Move me to TowerGame thanks.
var() const editconst int BlockWidth;
var() const editconst int BlockHeight;

function ActivateHUDPreview()
{
	local PointLightToggleable Light;
	PreviewBlock.SetHidden(FALSE);
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
	PreviewBlock.SetHidden(TRUE);
	foreach PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(FALSE);
	}
}

simulated function SetPreview(TowerPlaceable Placeable)
{
//	PreviewBlock.StaticMeshComponent.SetStaticMesh(Placeable.GetPlaceableStaticMesh());
//	PreviewBlock.StaticMeshComponent.SetMaterial(0, Placeable.GetPlaceableMaterial(0));
//	Placeable.AttachPlaceable(None);
	PreviewBlock.StaticMeshComponent.SetTranslation(Vect(0,0,0));
	PreviewBlock.StaticMeshComponent.SetStaticMesh(TowerBlock(Placeable).StaticMeshComponent.StaticMesh);
	PreviewBlock.StaticMeshComponent.SetMaterial(0, TowerBlock(Placeable).StaticMeshComponent.GetMaterial(0));
}

DefaultProperties
{
	// 256 probably best, could fit several people in.
	BlockWidth = 256
	BlockHeight = 256
}