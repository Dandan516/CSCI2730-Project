// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/FileStorage.sol";
import "contracts/UserSystem.sol";

contract FileSystem is UserSystem {

    uint16 private constant MAX_GLOBAL_FILES = 1000;
    uint16 private constant MAX_GLOBAL_DIRS = 1000;
    uint16 private constant MAX_DIRS = 10;

    struct Directory {
        string directoryName;
        uint id;
        bool exists;
        uint parent;
        uint[] children;
        FileStorage currentFiles;
    }
    
    uint globalFileCount;
    uint globalDirCount;
    string driveName;

    Directory root;
    Directory currentDir;
    mapping(uint => Directory) directories;

    constructor(string memory _driveName) {
        driveName = _driveName;
        root = Directory({
            directoryName: "/",
            id: 0,
            exists: true,
            parent: 0,
            children: new uint[](MAX_DIRS),
            currentFiles: new FileStorage()
        });
        currentDir = root;
        directories[0] = root;
        globalDirCount = 1;
    }

    event DirectoryCreated(string directoryName);
    event DirectoryRenamed(string directoryName);
    event DirectoryDeleted(string directoryName);

    // check if the directory name is available in the parent directory
    modifier directoryNameAvailable(string memory _newName) {
        uint[] memory siblings = directories[currentDir.parent].children;
        string memory siblingName;
        bool nameAvailable = true;
        
        for (uint i = 0; i < siblings.length; i++) {
            siblingName = directories[siblings[i]].directoryName;
            if (keccak256(abi.encodePacked(siblingName)) == keccak256(abi.encodePacked(_newName))) {
                nameAvailable = false;
                break;
            }
        }

        require(nameAvailable, "Name not available");
        _;
    }

    modifier notExceedGlobalFileLimit() {
        require(globalFileCount < MAX_GLOBAL_FILES, "Exceeded global file limit");
        _;
    }

    modifier notExceedGlobalDirLimit() {
        require(globalDirCount < MAX_GLOBAL_DIRS, "Exceeded global directory limit");
        _;
    }

    
    function createDirectory(string memory _directoryName) notExceedGlobalFileLimit external {
        directories[globalDirCount] = Directory({
            directoryName: _directoryName,
            id: globalDirCount,
            exists: true,
            parent: currentDir.id,
            children: new uint[](MAX_DIRS),
            currentFiles: new FileStorage()
        });
        globalDirCount++;
    }

    // rename current directory 
    function renameDirectory(string memory _newName) external directoryNameAvailable(_newName) {   
        currentDir.directoryName = _newName;
        emit DirectoryRenamed(_newName);
    }

    // change to another directory
    function changeDirectory(uint _directoryId) external {
        currentDir = directories[_directoryId];
    }

    // create file using FileStorage.createFile
    function createFile(string memory _filename, string memory _content) external {
        currentDir.currentFiles.createFile(_filename, _content);
    }

    // not working, plz make it work
    // list directory, ret[0] are directories, ret[1] are files
    function listDirectory() external view returns(string[][] memory) {
        string[][] memory ret;
        for (uint i = 0; i < currentDir.children.length; i++) {
            ret[0][i] = directories[currentDir.children[i]].directoryName;
        }
        ret[1] = currentDir.currentFiles.getFileList();
        return ret;
    }
    
}