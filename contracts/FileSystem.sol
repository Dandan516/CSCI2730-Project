// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/FileStorage.sol";
import "contracts/UserSystem.sol";

contract FileSystem is UserSystem() {

    uint16 private constant MAX_GLOBAL_FILES = 1000;
    uint16 private constant MAX_GLOBAL_DIRS = 1000;
    uint16 private constant MAX_DIRS = 10;

    struct Directory {
        string dirName;
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
    mapping(uint => Directory) dirs;

    constructor(string memory _driveName) {
        driveName = _driveName;
        root = Directory({
            dirName: "/",
            id: 0,
            exists: true,
            parent: 0,
            children: new uint[](0),
            currentFiles: new FileStorage()
        });
        currentDir = root;
        dirs[0] = root;
        globalDirCount = 1;
    }

    event DirectoryCreated(string dirName);
    event DirectoryRenamed(string dirName);
    event DirectoryDeleted(string dirName);
    event FileCreated(string filename, string content);
    event FileRenamed(string filename, string newName);
    event AppendedToFile(string filename, string newContent);
    event FileWritten(string filename, string newContent);
    event FileDeleted(string filename);

    // check if the directory name is available in the parent directory
    modifier dirNameAvailable(string memory _newName) {
        uint[] memory siblings = dirs[currentDir.parent].children;
        string memory siblingName;
        bytes memory b = bytes(_newName);

        bool nameAvailable = true;
        for (uint i = 0; i < siblings.length; i++) {
            siblingName = dirs[siblings[i]].dirName;
            if (keccak256(abi.encodePacked(siblingName)) == keccak256(abi.encodePacked(_newName))) {
                nameAvailable = false;
                break;
            }
        }
        require(nameAvailable, "Name not available");

        require(b.length > 0 && b.length <= 30, "Length of name should be between 1 to 30 characters");

        bool onlyAlphaNumeric = true;
        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) && //0-9
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x5F) && //_
                !(char == 0x20) // whitespace
            ) 
            {
                onlyAlphaNumeric = false;
                break;
            }
        }
        require(onlyAlphaNumeric == true, "Name should only contain alphanumeric characters, whitespaces or underscores");
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
            currentFiles: new FileStorage()
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
        currentDir.currentFiles.createFile(_filename, _content);
        dirs[currentDir.id] = currentDir;
        emit FileCreated(_filename, _content);
    }

    // append to file using FileStorage.appendToFile
    function appendToFile(string memory _filename, string memory _newContent) external {
        currentDir.currentFiles.appendToFile(_filename, _newContent);
        dirs[currentDir.id] = currentDir;
        emit AppendedToFile(_filename, _newContent);
    }

    // append to file using FileStorage.writeFile
    function writeToFile(string memory _filename, string memory _newContent) external {
        currentDir.currentFiles.writeFile(_filename, _newContent);
        dirs[currentDir.id] = currentDir;
        emit FileWritten(_filename, _newContent);
    }

    function deleteFile(string memory _filename) external {
        currentDir.currentFiles.deleteFile(_filename);
        dirs[currentDir.id] = currentDir;
        emit FileDeleted(_filename);
    }
    
    // read file using FileStorage.readFile
    function readFile(string memory _filename) external view returns(string memory) {
        return currentDir.currentFiles.readFile(_filename);
    }

    // list directory
    function listDir() external view returns(string[][2] memory) {
        string[] memory childDirList = new string[](currentDir.children.length);
        for (uint i = 0; i < currentDir.children.length; i++) {
            childDirList[i] = dirs[currentDir.children[i]].dirName;
        }
        string[] memory childFileList = currentDir.currentFiles.listFiles();
        return [childDirList, childFileList];
    }

    function viewCurrentDirName() external view returns(string memory) {
        return currentDir.dirName;
    }

}