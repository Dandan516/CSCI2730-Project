// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract FileStorage {
    address public drive_owner;

    struct File {
        string filename;
        string content;
        bool exists;
        address file_owner;
        mapping(address => bool) read_access;
        mapping(address => bool) write_access;
    }

    mapping(string => File) private files;
    string[] private fileList;

    event FileCreated(string filename, string content);
    event FileEdited(string filename, string content);
    event FileDeleted(string filename);

    modifier onlyOwner() {
        require(msg.sender == drive_owner, "Not the contract owner");
        _;
    }

    modifier fileExists(string memory _filename) {
        require(files[_filename].exists, "File does not exist");
        _;
    }

    constructor() {
        drive_owner = msg.sender;
    }

    // Create a file
    function createFile(string memory _filename, string memory _content) public {
        require(bytes(_filename).length > 0, "Filename cannot be empty");
        require(!files[_filename].exists, "File already exists");

        File storage new_file = files[_filename];
        new_file.filename = _filename;
        new_file.content = _content;
        new_file.exists = true;
        new_file.file_owner = msg.sender;
        new_file.read_access[msg.sender] = true;
        new_file.write_access[msg.sender] = true;

        // Add to File list
        fileList.push(_filename);
        emit FileCreated(_filename, _content);
    }

    //Read a file by file name
    function readFile(string memory _filename) public view fileExists(_filename) returns (string memory) {
        require(files[_filename].read_access[msg.sender], "No read access");
        return files[_filename].content;
    }

    //Edit a file
    function editFile(string memory _filename, string memory _newContent) public fileExists(_filename) {
        require(files[_filename].write_access[msg.sender], "No write access");
        files[_filename].content = _newContent;
        emit FileEdited(_filename, _newContent);
    }

    //Delete a file
    function deleteFile(string memory _filename) public onlyOwner fileExists(_filename) {
        delete files[_filename];

        // Remove from file list
        for (uint i = 0; i < fileList.length; i++) {
            if (keccak256(abi.encodePacked(fileList[i])) == keccak256(abi.encodePacked(_filename))) {
                fileList[i] = fileList[fileList.length - 1]; 
                fileList.pop();
                break;
            }
        }
        emit FileDeleted(_filename);
    }

    function viewFilePermission(string memory _filename, address _addr) public view fileExists(_filename) returns (bool[2] memory) {
        bool read = files[_filename].read_access[_addr];
        bool write = files[_filename].write_access[_addr];
        return [read, write];
    }


    // List of filenames
    function getFileList() public view returns (string[] memory) {
        return fileList;
    }
}
