// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/FileStorage.sol";
import "contracts/UserSystem.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ShareDrive is UserSystem {

    uint private constant MAX_GLOBAL_FILES = 1000;
    uint private constant MAX_DIRS = 10;

    struct Directory {
        string dirName;
        uint id;
        bool exists;
        uint parent;
        uint[] children;
        FileStorage currentFiles;
    }
    
    uint globalFileCount;
    uint dirIdCount;
    string driveName;
    Directory root;
    Directory public currentDir; // for debug only, remove modifier later
    mapping(uint => Directory) dirs;
    mapping(string => uint) idByName;
    
    // root dir id is 1
    constructor(string memory _driveName) {
        driveName = _driveName;
        root = Directory({
            dirName: "/",
            id: 1,
            exists: true,
            parent: 1,
            children: new uint[](0),
            currentFiles: new FileStorage()
        });
        currentDir = root;
        dirs[1] = root;
        idByName[root.dirName] = 1;
        dirIdCount = 2; // other dir start from id 2
    }

    event ShareDriveRenamed(string newName);
    event DirectoryCreated(string dirName);
    event DirectoryRenamed(string oldname, string newNames);
    event DirectoryDeleted(string dirName);
    event FileCreated(string filename, string content);
    event FileRenamed(string oldname, string newName);
    event AppendedToFile(string filename, string newContent);
    event FileWritten(string filename, string newContent);
    event FileDeleted(string filename);
    event FilePermissionChanged(string filename, address addr, uint8 mode);

    // check if the directory name is available in the parent directory
    modifier dirNameValid(string memory _newName) {
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

    modifier onlyFileOwner(string memory _filename) {
        address _fileOwner = currentDir.currentFiles.getFileOwner(_filename);
        require(msg.sender == _fileOwner, "You are not the file owner");
        _;
    }

    modifier notExceedGlobalFileLimit() {
        require(globalFileCount < MAX_GLOBAL_FILES, "Exceeded global file limit");
        _;
    }

    modifier notExceedDirLimit(uint _dirId) {
        require(dirs[_dirId].children.length < MAX_DIRS, "Exceeded local dir limit");
        _;
    }
    
    function createDir(string memory _dirName) external notExceedDirLimit(idByName[_dirName]) {
        uint newDirId = dirIdCount;
        dirs[newDirId] = Directory({
            dirName: _dirName,
            id: dirIdCount,
            exists: true,
            parent: currentDir.id,
            children: new uint[](0),
            currentFiles: new FileStorage()
        });
        dirs[currentDir.id].children.push(dirIdCount);
        currentDir = dirs[currentDir.id];
        idByName[dirs[newDirId].dirName] = newDirId;
        dirIdCount++;
    }

    // rename current directory
    function renameDir(string memory _newName) dirNameValid(_newName) external {  
        require(currentDir.id != 0, "Cannot rename root");
        string memory _oldName = dirs[currentDir.id].dirName;
        dirs[currentDir.id].dirName = _newName;
        currentDir = dirs[currentDir.id];
        emit DirectoryRenamed(_oldName, _newName);
    }

    // delete current directory, go back to parent
    function deleteDir() external {
        require(currentDir.id != 0, "Cannot delete root");
        delete dirs[currentDir.id];
        delete idByName[currentDir.dirName];
        changeDir(currentDir.parent);
        // Remove from child list
        for (uint i = 0; i < currentDir.children.length; i++) {
            if (currentDir.children[i] == currentDir.id) {
                currentDir.children[i] = currentDir.children[currentDir.children.length - 1]; 
                currentDir.children.pop();
                break;
            }
        }
        dirs[currentDir.id] = currentDir;
    }

    // go up to parent dir
    function goUp() external {
        changeDir(currentDir.parent);
    }

    // go down to the specified child dir
    function goDown(string memory _dirName) external {
        uint dirId = idByName[_dirName];
        bool isChild = false;
        for (uint i; i < currentDir.children.length; i++) {
            if (currentDir.children[i] == dirId) {
                isChild = true;
            }
        }
        require(isChild, "Directory does not exist");
        changeDir(dirId);
    }

    // create file using FileStorage.createFile
    function createFile(string memory _filename, string memory _content) external notExceedGlobalFileLimit {
        currentDir.currentFiles.createFile(_filename, msg.sender, _content);
        dirs[currentDir.id] = currentDir;
        //currentDir.currentFiles.fileOwner = msg.sender;
        //currentDir.currentFiles.changeFilePermission(_filename, msg.sender, 3);
        emit FileCreated(_filename, _content);
    }

    function renameFile(string memory _oldName, string memory _newName) external {
        currentDir.currentFiles.renameFile(_oldName, _newName);
        dirs[currentDir.id] = currentDir;
        emit FileRenamed(_oldName, _newName);
    }

    // append to file using FileStorage.appendToFile
    function appendToFile(string memory _filename, string memory _newContent) external {
        uint8 access = currentDir.currentFiles.getMode(_filename, msg.sender);
        require(access >= 2, "No append access");
        currentDir.currentFiles.appendToFile(_filename, _newContent);
        dirs[currentDir.id] = currentDir;
        emit AppendedToFile(_filename, _newContent);
    }

    // append to file using FileStorage.writeFile
    function writeToFile(string memory _filename, string memory _newContent) external {
        uint8 access = currentDir.currentFiles.getMode(_filename, msg.sender);
        require(access >= 3, "No write access");
        currentDir.currentFiles.writeFile(_filename, _newContent);
        dirs[currentDir.id] = currentDir;
        emit FileWritten(_filename, _newContent);
    }

    function deleteFile(string memory _filename) external onlyFileOwner(_filename)  {
        currentDir.currentFiles.deleteFile(_filename);
        dirs[currentDir.id] = currentDir;
        emit FileDeleted(_filename);
    }
    
    // read file using FileStorage.readFile
    function readFile(string memory _filename) external view returns(string memory) {
        uint8 access = currentDir.currentFiles.getMode(_filename, msg.sender);
        require(access >= 1, "No read access");
        return currentDir.currentFiles.readFile(_filename);
    }

    // list directory
    function listDir() external view returns(string[][2] memory) {
        string[] memory childDirList = new string[](currentDir.children.length);
        for (uint i = 0; i < currentDir.children.length; i++) {
            childDirList[i] = string.concat(dirs[currentDir.children[i]].dirName, '/');
        }
        string[] memory childFileList = currentDir.currentFiles.listFiles();
        return [childDirList, childFileList];
    }

    function viewCurrentDirName() external view returns(string memory) {
        return currentDir.dirName;
    }

    // change the access mode of a user on a file
    function changeFilePermission(string memory _filename, address _addr, uint8 _mode) external userExists(_addr) onlyFileOwner(_filename) {
        currentDir.currentFiles.changeFilePermission(_filename, _addr, _mode);
        emit FilePermissionChanged(_filename, _addr, _mode); // Emit event for permission change
    }

    // returns the description of a user's mode
    function viewFilePermission(string memory _filename, address _addr) external view userExists(_addr) returns (string memory) {
        return currentDir.currentFiles.viewFilePermission(_filename, _addr);
    }

    // change to another directory
    function changeDir(uint _dirId) internal {
        require(dirs[_dirId].exists, "Directory does not exist");
        currentDir = dirs[_dirId];
    }

}
