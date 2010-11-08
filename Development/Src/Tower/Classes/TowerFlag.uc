/**
TowerFlag

Lives on from Cube. A cloth-ready skeletal mesh with a ScriptedTexture that draws an image to it from a file on the
user's computer.
*/
class TowerFlag extends SkeletalMeshActorSpawnable
	config(Tower)
	DLLBind(DevILWrapper);

var ScriptedTexture Texture;
var MaterialInstanceConstant MaterialInstance;

var int i;
var int X, Y;
var int Width, Height;
var int PixelsDrawn;
//var StaticMeshComponent SMC;

/** Loading the DLL can't be avoided, but setting this to false results in no dllimport function calls.*/
var config bool bEnable;
/** Number of frames to split up the rendering through. Higher it is the longer it takes but causes less lag.*/
var config int NumberOfFramesToCompleteRenderBy;
var config bool bLogDrawing;
var config string ExternalTextureFilePath;

/** Ensures that DevIL is initialized. Subsequent calls have no effect if already initialzed.*/
dllimport final function Initialize();
/** Loads given image. For supported formats see DevIL site. Transparency values are discarded.
* If returns true, Width and Height hold the loaded image's width and height.*/
dllimport final function bool DevILLoadImage(string FilePath, out int ImageWidth, out int ImageHeight);
/** Gets next pixel RGB values. Internally counted by DevILWrapper.*/
dllimport final function GetNextPixel(out int Red, out int Green, out int Blue);
dllimport final function DevILUnloadImage();
//dllimport final function bool GetLogString()

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	Initialize();
	if(DevILLoadImage(ExternalTextureFilePath, Width, Height))
	{
		`log("Loaded image successfully!");
	}
	else
	{
		`log("Image did not load!");
	}
	Texture = ScriptedTexture(class'ScriptedTexture'.static.Create(Width, Width,,, false));
	Texture.Render = DrawCustomTexture;
	MaterialInstance = SkeletalMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	MaterialInstance.SetTextureParameterValue('FlagTexture', Texture);
}

// FIXME: Broke NumberOfFramesToCompleteRenderBy
/** Rendering delegate for ScriptedTexture.*/
function DrawCustomTexture(Canvas Canvas)
{
	local int R, G, B;
	local int pixelsThisTime;
	local Color PixelColor;
	while(((Width*Height) % NumberOfFramesToCompleteRenderBy) != 0)
	{
		NumberOfFramesToCompleteRenderBy++;
	}
	pixelsThisTime = 0;
	while(Y <= Height)
	{
		Canvas.SetPos(X, Y);
		GetNextPixel(R, G, B);
		PixelColor.A = 255;
		PixelColor.R = R;
		PixelColor.G = G;
		PixelColor.B = B;
		Canvas.DrawTile(Canvas.DefaultTexture, 1, 1, 0, 0, 1, 
			1, ColorToLinearColor(PixelColor));
		//`log("Drawing pixel"@i@"("$X$", "$Y$")"$":"@R@G@B);
		X++;
		if(X >= Width)
		{
			X = 0;
			Y++;
			//`log("Shifting to row"@Y@"and setting X to"@X);
		}
		pixelsThisTime++;
		if(pixelsThisTime >= ((Width*Height)/NumberOfFramesToCompleteRenderBy))
			break;
	}
	PixelsDrawn += pixelsThisTime;
	//log("Drew"@PixelsDrawn@"pixels total!");
	if(PixelsDrawn < Width*Height)
	{
		Texture.bSkipNextClear = true;
		Texture.bNeedsUpdate = true;
	}
	else
	{
		`log("Finished all ScriptedTexture rendering!");
		Texture.bNeedsUpdate = false;
		DevILUnloadImage();
	}
//	`log("Done drawing custom texture!");
}

DefaultProperties
{
	
	/*Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'TestMess.TestCloth06'
		Materials(0)=Material'TestMess.Materials.TestFlag'
		bEnableClothSimulation=true
	End Object*/
}