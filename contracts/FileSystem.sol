// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/FileStorage.sol";
import "contracts/UserSystem.sol";

contract FileSystem is UserSystem {

    uint16 private constant MAX_GLOBAL_FILES = 1000;
    uint16 private constant MAX_GLOBAL_DIRS = 1000;
    uint16 private constant MAX_DIRS = 10;

    struct Directory {
        string dirName;
        uint id;
        bool exists;
        uint parent;
        uint[] children;
        FileStorage files;
    }
    
    uint globalFileCount;
    uint globalDirCount;
    string driveName;

    Directory root;
    Directory currentDir;
    mapping(uint => Directory) dirs;

    constructor(string memory _driveName) {
        driveName = _driveName;
        root = Directory({
            dirName: "/",
            id: 0,
            exists: true,
            parent: 0,
            children: new uint[](0),
            files: new FileStorage()
        });
        currentDir = root;
        dirs[0] = root;
        globalDirCount = 1;
    }

    event DirectoryCreated(string dirName);
    event DirectoryRenamed(string dirName);
    event DirectoryDeleted(string dirName);
    event FileCreated(string filename, string content);
    event FileEdited(string filename, string content);
    event FileDeleted(string filename);

    // check if the directory name is available in the parent directory
    modifier dirNameAvailable(string memory _newName) {
        uint[] memory siblings = dirs[currentDir.parent].children;
        string memory siblingName;
        bool nameAvailable = true;
        
        for (uint i = 0; i < siblings.length; i++) {
            siblingName = dirs[siblings[i]].dirName;
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
    
    function createDir(string memory _dirName) notExceedGlobalFileLimit external {
        dirs[globalDirCount] = Directory({
            dirName: _dirName,
            id: globalDirCount,
            exists: true,
            parent: currentDir.id,
            children: new uint[](0),
            files: new FileStorage()
        });
        dirs[currentDir.id].children.push(globalDirCount);
        currentDir = dirs[currentDir.id];
        globalDirCount++;
    }

    // rename current directory
    // maybe dont have to be curent directory?
    function renameDir(string memory _newName) external dirNameAvailable(_newName) {   
        dirs[currentDir.id].dirName = _newName;
        emit DirectoryRenamed(_newName);
    }

    // change to another directory
    function changeDir(uint _dirId) external {
        require(dirs[_dirId].exists, "Invalid directory id");
        currentDir = dirs[_dirId];
    }

    // create file using FileStorage.createFile
    function createFile(string memory _filename, string memory _content) external {
        currentDir.files.createFile(_filename, _content);
        dirs[currentDir.id] = currentDir;
        emit FileCreated(_filename, _content);
    }

    // append to file using FileStorage.readFile
    function appendToFile(string memory _filename) external returns(string memory) {
        currentDir.files.readFile(_filename);
        dirs[currentDir.id] = currentDir;
    }



    // read file using FileStorage.readFile
    function readFile(string memory _filename) external view returns(string memory) {
        currentDir.files.readFile(_filename);
        dirs[currentDir.id] = currentDir;
    }

    // list directory
    function listDir() external view returns(string[][2] memory) {
        string[] memory childDirList = new string[](currentDir.children.length);
        for (uint i = 0; i < currentDir.children.length; i++) {
            childDirList[i] = dirs[currentDir.children[i]].dirName;
        }
        string[] memory childFileList = currentDir.files.getFileList();
        return [childDirList, childFileList];
    }

    function viewCurrentDirName() external view returns(string memory) {
        return currentDir.dirName;
    }

}