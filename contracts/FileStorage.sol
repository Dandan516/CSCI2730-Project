// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract FileStorage {

    uint16 private constant MAX_FILES = 50;

    /* file permission mode:
        0: no access
        1: read only
        2: read & append
        3: read, append & write
    */
    struct File {
        string filename;
        string content;
        bool exists;
        address fileOwner;
        mapping(address => uint8) mode;
    }

    uint public fileCount = 0;
    mapping(string => File) public files;
    string[] private fileList;

    modifier fileExists(string memory _filename) {
        require(files[_filename].exists, "File does not exist");
        _;
    }

    modifier notExceedFileLimit {
        require(fileCount < MAX_FILES, "Exceeded file limit");
        _;
    }

    // Create a file
    function createFile(string memory _filename, address _addr, string memory _content) external notExceedFileLimit {
        require(bytes(_filename).length > 0, "Filename cannot be empty");
        require(!files[_filename].exists, "File already exists");

        File storage newFile = files[_filename];
        newFile.filename = _filename;
        newFile.content = _content;
        newFile.exists = true;
        newFile.fileOwner = _addr;
        newFile.mode[_addr] = 3;

        // Add to File list
        fileCount++; 
        fileList.push(_filename);
    }

    // Rename a file
    function renameFile(string memory _oldName, string memory _newName) external fileExists(_oldName) {
        require(!files[_newName].exists, "Name not available");
        File storage file = files[_oldName];
        delete files[_oldName];
        file.filename = _newName;
    }

    // Append to a file
    function appendToFile(string memory _filename, string memory _newContent) external fileExists(_filename) {
        // require(files[_filename].mode[msg.sender] >= 2, "No append access");
        files[_filename].content = string.concat(files[_filename].content, "\n", _newContent);
    }

    // Overwrite a file
    function writeFile(string memory _filename, string memory _newContent) external fileExists(_filename) {
        // require(files[_filename].mode[msg.sender] == 3, "No write access");
        files[_filename].content = _newContent;
    }

    // Delete a file
    function deleteFile(string memory _filename) external fileExists(_filename) {
        delete files[_filename];
        // Remove from file list
        for (uint i = 0; i < fileList.length; i++) {
            if (keccak256(abi.encodePacked(fileList[i])) == keccak256(abi.encodePacked(_filename))) {
                fileList[i] = fileList[fileList.length - 1]; 
                fileList.pop();
                break;
            }
        }
        fileCount--;
    }

    // change file permission mode of the address
    function changeFilePermission(string memory _filename, address _addr, uint8 _mode) external fileExists(_filename) {
        require(_mode >= 0 && _mode <= 3, "Invalid permission mode");
        files[_filename].mode[_addr] = _mode;
    }

    // Read a file by filename
    function readFile(string memory _filename) external view fileExists(_filename) returns (string memory) {
        // require(files[_filename].mode[msg.sender] >= 1, "No Read access");
        return files[_filename].content;
    }

    function viewFilePermission(string memory _filename, address _addr) external view fileExists(_filename) returns (string memory) {
        string[4] memory mode_description = ["No access", "Read only", "Read & append", "Read, append & write"];
        return mode_description[files[_filename].mode[_addr]];
    }

    // List of filenames
    function listFiles() external view returns (string[] memory) {
        return fileList;
    }

    function getMode(string memory _filename, address _addr) external view fileExists(_filename) returns (uint8) {  
        return files[_filename].mode[_addr];
    }

    function getFileOwner(string memory _filename) external view fileExists(_filename) returns (address) {
        return files[_filename].fileOwner;
    }
    
}