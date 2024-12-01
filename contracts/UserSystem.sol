// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract UserSystem {

    uint16 private constant MAX_USERS = 20;
    
    struct User {
        address addr;
        uint16 id;
        string username;
        bool exists;
    }

    User driveOwner;
    uint16 userCount;
    uint16 idCount;

    mapping(address => User) users;
    mapping(uint16 => address) byId;
    mapping(string => address) byName;

    event UserAdded(address indexed _addr);
    event UsernameChanged(address indexed _addr, string newName);
    event UserRemoved(address indexed _addr);

    modifier onlyDriveOwner() {
        require(msg.sender == driveOwner.addr, "Only the drive owner can do this");
        _;
    }

    modifier userExists(address _addr) {
        require(users[_addr].exists, "User does not exist");
        _;
    }

    modifier notExceedUserLimit {
        require(userCount < MAX_USERS, "Exceeded user limit");
        _;
    }

    // add drive owner to users[]
    constructor() {
        driveOwner = User({
            addr: msg.sender,
            id: 0,
            username: "Owner",
            exists: true
        });
        users[msg.sender] = driveOwner;
        byId[driveOwner.id] = driveOwner.addr;
        byName[driveOwner.username] = driveOwner.addr;
        userCount = 1;
        idCount = 1;
    }

    // add user to users[]
    function addUser(address _addr) onlyDriveOwner external {
        require(!users[_addr].exists, "User already exists");
        User memory newUser = User({
            addr: _addr,
            id: idCount,
            username: string.concat("User ", Strings.toString(userCount)),
            exists: true
        });
        users[_addr] = newUser;
        byId[newUser.id] = _addr;
        byName[newUser.username] = _addr;
        userCount += 1;
        idCount += 1;

        emit UserAdded(_addr);
    }

    function changeSelfUsername(string memory _newName) external {
        require(byName[_newName] == address(0), "Name not available");
        delete byName[users[msg.sender].username];
        users[msg.sender].username = _newName;

        emit UsernameChanged(msg.sender, _newName);
    }

    function removeUser(address _addr) onlyDriveOwner userExists(_addr) external {
        require(_addr != msg.sender, "Cannot remove owner");
        delete byId[users[_addr].id];
        delete byName[users[_addr].username];
        delete users[_addr];
        userCount -= 1;
        
        emit UserRemoved(_addr);
    }

    // view the address of the drive owner
    function viewDriveOwner() external view returns(address) {
        return driveOwner.addr;
    }

    // view the number of users
    function viewNumOfUsers() external view returns(uint) {
        return userCount;
    }

    // view the whitelisted addresses
    function viewWhitelist() external view returns(address[] memory) {
        address[] memory result = new address[](userCount);
        for (uint8 i = 0; i < userCount; i++) {
            result[i] = byId[i];
        }
        return result;
    }

    // view username of the address
    function viewUsername(address _addr) userExists(_addr) external view returns(string memory) {
        return users[_addr].username;
    }

}

