// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the SAVESYSTEM_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// SAVESYSTEM_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.

#define POCO_STATIC

#ifdef SAVESYSTEM_EXPORTS
#define SAVESYSTEM_API __declspec(dllexport)
#else
#define SAVESYSTEM_API __declspec(dllimport)
#endif

#include "Poco\Types.h"
#include <assert.h>
using namespace Poco;
/**
General file layout:
FileHeader
Tower
TowerNameCount amount of Chars
BlockCount amount of Blocks.
Game
FileFooter
*/

struct FString
{
	wchar_t* Data;
	int ArrayNum;
	int ArrayMax;

	void UpdateArrayNum()
	{
		ArrayNum = wcslen(Data)+1;
		assert(ArrayNum <= ArrayMax);
	}
};

struct FVector
{
	float X, Y, Z;
};

struct IVector
{
	Int16 X, Y, Z;
};

struct IVector8
{
	Int8 X, Y, Z;
};

extern "C"
{
	SAVESYSTEM_API UInt32 StartFile(const wchar_t* FileName, unsigned char bSaving);
	SAVESYSTEM_API void SaveAllData(Int32 Version, unsigned char bTowerOnly, const wchar_t* TowerName, 
		Int32 NodeCount);
	SAVESYSTEM_API void ReadAllFile();
	SAVESYSTEM_API void SetHeader(Int32 Version, unsigned char bTowerOnly);
	SAVESYSTEM_API void SetTowerData(const wchar_t* TowerName, Int32 NodeCount);
	SAVESYSTEM_API void AddBlock(const wchar_t* ClassName, unsigned char bRoot, FVector* GridLocation, 
		FVector* ParentDirection);
	SAVESYSTEM_API void EndAddBlock();
	
	SAVESYSTEM_API void GetTowerData(wchar_t* TowerName, Int32* NodeCount);
	SAVESYSTEM_API void GetHeader(Int32* Version, unsigned char* bTowerOnly);
	SAVESYSTEM_API void StartGetBlock();
	SAVESYSTEM_API void GetBlock(wchar_t* ClassName, unsigned char* bRoot, FVector* GridLocation,
		FVector* ParentDirection);
	SAVESYSTEM_API void EndFile();
}

struct FileHeader
{
	// Version of the save file. Used to identify and still use previous save files in current
	// copies of games.
	UInt8 Version;
	// If TRUE, this save file only holds data on a tower. If FALSE, it holds data on a tower
	// and a game in progress.
	UInt8 bTowerOnly;
};

struct Tower
{
	// Number of blocks in this tower.
	UInt16 BlockCount;
	// Length of the name of the tower.
	UInt16 TowerNameCount;
	// What follows is a TowerNameCount amount of wchar_ts.
//	wchar_t* TowerName;
};

struct ID
{
	UInt8 BlockIDCount;
	// What follows is a BlockIDCount of BlockIDs.
};

struct BlockID
{
//	UInt8 ID;
	UInt8 ClassNameLength;
	// What follows is a ClassNameLength amount of wchar_ts.
};

struct Block
{
	// Represents the class of block.
	//@NOTE - If modding is enabled and if saving blocks is allowed, this'll have to be made
	// a larger int in order to accomadate custom blocks.
	UInt8 ID;
	//@TODO - Remove me.
	UInt8 bRoot;
	// Unit vector specifying direction of this block's parent.
	IVector8 ParentDirection;
	// Grid coordinates of block.
	IVector GridLocation;
};

// Saving block type.
// Dynamically and automatically construct a list of IDs associated with strings of the class name.
// At load time, use that list to send back a string of the class name, use DynamicLoadObject to get
// the class of it, and spawn it as normal.

struct Game
{
	UInt8 Round;
};

struct FileFooter
{

};

struct File
{
	FileHeader Header;
	Tower TowerData;
};