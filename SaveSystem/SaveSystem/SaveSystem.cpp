// SaveSystem.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "SaveSystem.h"
#include <string>
#include <vector>
#include <sstream>
#include "Shlobj.h"

HANDLE SaveFile;

// Saving variables.
std::vector<Block> Blocks;
//std::vector<UInt8> BlockIDs;
std::vector<wchar_t*> BlockClassNames;

// Loading variables.
UInt8* BlockIDCount;
std::vector<wchar_t*> BlockClasses;
Block* LoadBlocks; 
UInt16 BlockCount;
int BlockIteration = 0;

extern "C"
{
	UInt32 StartFile(const wchar_t* FileName, unsigned char bSaving)
	{
		std::wstringstream FullPath;
		LPWSTR AppDataPath = NULL;
		HRESULT hResult = SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_DONT_UNEXPAND, NULL, 
			&AppDataPath);
		FullPath << AppDataPath << L"\\Tower\\";
		CreateDirectory(FullPath.str().c_str(), nullptr);
		FullPath << FileName << L".sav";
//		MessageBox(NULL, FullPath.str().c_str(), L"SaveSystem", NULL);
		DWORD CreationDisposition, DesiredAccess;
		if(bSaving)
		{
			CreationDisposition = CREATE_ALWAYS;
			DesiredAccess = GENERIC_WRITE;
		}
		else
		{
			CreationDisposition = OPEN_ALWAYS;
			DesiredAccess = GENERIC_READ;
		}
		SaveFile = CreateFile(FullPath.str().c_str(), DesiredAccess, 0, nullptr, CreationDisposition,
			FILE_ATTRIBUTE_NORMAL, nullptr);
		if(SaveFile == INVALID_HANDLE_VALUE)
		{
			return 0;
		}
		else
		{
			return 1;
		}
	}
	void SetHeader(Int32 Version, unsigned char bTowerOnly)
	{
		DWORD BytesWritten;
		FileHeader Header;
		Header.Version = Version;
		Header.bTowerOnly = bTowerOnly;
		WriteFile(SaveFile, &Header, sizeof(Header), &BytesWritten, nullptr);
	}
	void SetTowerData(const wchar_t* TowerName, Int32 NodeCount)
	{
		DWORD BytesWritten;
		Tower FileTower;
		FileTower.BlockCount = (UInt32)NodeCount;
		FileTower.TowerNameCount = wcslen(TowerName);
		WriteFile(SaveFile, &FileTower, sizeof(Tower), &BytesWritten, nullptr);
		//wchar_t* SaveTowerName = new wchar_t[wcslen(TowerName)];
		for(int i = 0; i < wcslen(TowerName); i++)
		{
			WriteFile(SaveFile, &TowerName[i], sizeof(wchar_t), &BytesWritten, nullptr);
		}
	}
	void AddBlock(const wchar_t* ClassName, unsigned char bRoot, FVector* GridLocation, 
		FVector* ParentDirection)
	{
		Block NewBlock;
		UInt8 ID = 0;
		bool bFoundID = false;
		for(int i = 0; i < BlockClassNames.size(); i++)
		{
			if(wcscmp(ClassName, BlockClassNames[i]) == 0)
			{
				NewBlock.ID = i;
				bFoundID = true;
				break;
			}
		}
		if(!bFoundID)
		{
			wchar_t* NewClassName = new wchar_t[wcslen(ClassName)];
			wcscpy(NewClassName, ClassName);
			BlockClassNames.push_back(NewClassName);
			NewBlock.ID = BlockClassNames.size()-1;
			bFoundID = true;
		}
		NewBlock.bRoot = bRoot;
		NewBlock.GridLocation.X = (Int16)GridLocation->X;
		NewBlock.GridLocation.Y = (Int16)GridLocation->Y;
		NewBlock.GridLocation.Z = (Int16)GridLocation->Z;
		NewBlock.ParentDirection.X = (Int8)ParentDirection->X;
		NewBlock.ParentDirection.Y = (Int8)ParentDirection->Y;
		NewBlock.ParentDirection.Z = (Int8)ParentDirection->Z;
		Blocks.push_back(NewBlock);
	}
	void EndAddBlock()
	{
		DWORD BytesWritten;
		UInt8 IDCount = BlockClassNames.size();
		// Write the number of different classes/IDs we're saving.
		WriteFile(SaveFile, &IDCount, sizeof(UInt8), &BytesWritten, nullptr);
		// Write all the lengths of the class names. The order they're written in will serve as the
		// ID number.
//		wchar_t* IDs = new UInt8[IDCount];
		for(int i = 0; i < IDCount; i++)
		{
			UInt8 ClassNameLength = wcslen(BlockClassNames[i]);
			WriteFile(SaveFile, &ClassNameLength, sizeof(UInt8), &BytesWritten, nullptr);
		}
		for(int i = 0; i < IDCount; i++)
		{
			WriteFile(SaveFile, &BlockClassNames[i], sizeof(wchar_t)*wcslen(BlockClassNames[i]),
				&BytesWritten, nullptr);
		}
		for(int i = 0; i < Blocks.size(); i++)
		{
			WriteFile(SaveFile, &Blocks[i], sizeof(Block), &BytesWritten, nullptr);
		}
//		WriteFile(SaveFile, 
	}
	

	void GetTowerData(wchar_t* TowerName, Int32* NodeCount)
	{
		DWORD BytesRead;
		Tower FileTower;
		ReadFile(SaveFile, &FileTower, sizeof(Tower), &BytesRead, nullptr);
//		wchar_t* TowerReadName = new wchar_t[10];
		ReadFile(SaveFile, TowerName, sizeof(wchar_t)*FileTower.TowerNameCount, 
			&BytesRead, nullptr);
		DWORD Error = GetLastError();
		TowerName[FileTower.TowerNameCount] = L'\0';
		*NodeCount = FileTower.BlockCount;
		BlockCount = FileTower.BlockCount;
//		TowerName = TowerReadName;
	}
	void GetHeader(Int32* Version, unsigned char* bTowerOnly)
	{
		SetFilePointer(SaveFile, 0, nullptr, FILE_BEGIN);
		DWORD BytesRead;
		FileHeader Header;
		ReadFile(SaveFile, &Header, sizeof(Header), &BytesRead, nullptr);
		*Version = Header.Version;
		*bTowerOnly = Header.bTowerOnly;
	}
	void StartGetBlock()
	{
		BlockClasses.clear();
		Blocks.clear();
		std::vector<UInt8> NameLengths;
		DWORD BytesRead;
		UInt8 BlockIDCount;
		ReadFile(SaveFile, &BlockIDCount, sizeof(UInt8), &BytesRead, nullptr);
		UInt8 ClassNameLength;
		for(int i = 0; i < BlockIDCount; i++)
		{
			ReadFile(SaveFile, &ClassNameLength, sizeof(UInt8), &BytesRead, nullptr);
			NameLengths.push_back(ClassNameLength);
		}
		wchar_t* LastReadBlockClass;
		for(int i = 0; i < BlockIDCount; i++)
		{
			LastReadBlockClass = new wchar_t[NameLengths[i]];
			ReadFile(SaveFile, LastReadBlockClass, sizeof(wchar_t)*NameLengths[i], &BytesRead, nullptr);
			BlockClasses.push_back(new wchar_t[NameLengths[i]]);
			wcscpy(BlockClasses[i], LastReadBlockClass);
		}
		LoadBlocks = new Block[BlockCount];
		ReadFile(SaveFile, &LoadBlocks, sizeof(Block)*BlockCount, &BytesRead, nullptr);
		delete LastReadBlockClass;
	}
	void GetBlock(wchar_t* ClassName, unsigned char* bRoot, FVector* GridLocation,
		FVector* ParentDirection)
	{
		ClassName = wcscpy(ClassName, BlockClasses[LoadBlocks[BlockIteration].ID]); 
		BlockIteration++;
	}
	void SaveAllData(Int32 Version, unsigned char bTowerOnly, const wchar_t* TowerName, Int32 NodeCount)
	{
		DWORD BytesWritten;
		File FileData;
		FileData.Header.bTowerOnly = bTowerOnly;
		FileData.Header.Version = Version;
		FileData.TowerData.BlockCount = NodeCount;
		FileData.TowerData.TowerNameCount = wcslen(TowerName);
		for(int i = 0; i < wcslen(TowerName); i++)
		{
					WriteFile(SaveFile, &TowerName[i], sizeof(wchar_t), &BytesWritten, nullptr);
		}
	}
	void ReadAllFile()
	{
		DWORD Test = sizeof(wchar_t*);
//		UInt32 TowerNameLength;
		DWORD BytesRead;
		LARGE_INTEGER FileSize;
		GetFileSizeEx(SaveFile, &FileSize);
		DWORD Error = GetLastError();
		File TowerFile;
	//	DWORD Offset = SetFilePointer(SaveFile, 6, nullptr, FILE_BEGIN);
	//	ReadFile(SaveFile, &TowerNameLength, sizeof(UInt32), &BytesRead, nullptr);
	//	SetFilePointer(SaveFile, 0, nullptr, FILE_BEGIN);
	//	TowerFile.TowerData.TowerName = new wchar_t[TowerNameLength];
		ReadFile(SaveFile, &TowerFile, FileSize.LowPart, &BytesRead, nullptr);
		EndFile();
	}
	void EndFile()
	{
		CloseHandle(SaveFile);
	}
}