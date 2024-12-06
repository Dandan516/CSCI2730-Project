// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract UserSystem {
    
    struct User {
        address addr;
        uint id;
        string username;
        bool exists;
    }

    User public driveOwner;
    //User public currentUser;
    uint public userCount;
    uint internal idCount;
    mapping(address => User) users;
    mapping(uint => address) internal userById;
    mapping(string => address) internal userByName;

    event UserAdded(address indexed addr);
    event UserRenamed(address indexed addr, string newName);
    event UserRemoved(address indexed addr);

    modifier onlyDriveOwner() {
        require(msg.sender == driveOwner.addr, "You are not the drive owner");
        _;
    }

    modifier userExists(address _addr) {
        require(users[_addr].exists, "User does not exist");
        _;
    }

    constructor() {
        driveOwner = User({
            addr: msg.sender,
            id: 0,
            username: "Owner",
            exists: true
        });
        users[msg.sender] = driveOwner;
        userById[driveOwner.id] = driveOwner.addr;
        userByName[driveOwner.username] = driveOwner.addr;
        userCount = 1;
        idCount = 1;
    }

    // on whitelist, grant read permission to all files
    function addUser(address _addr) external {
        require(!users[_addr].exists, "User already exists");               
        // add user into the userList list
        User memory newUser = User({
            addr: _addr,
            id: idCount,
            username: string.concat("User ", Strings.toString(userCount)),
            exists: true
        });
        users[_addr] = newUser;
        userById[newUser.id] = newUser.addr;
        userByName[newUser.username] = newUser.addr;
        userCount += 1;
        idCount += 1;
        emit UserAdded(_addr);
    }

    function renameSelf(string memory _newName) external {
        require(userByName[_newName] == address(0), "Name not available");
        string memory _oldName = users[msg.sender].username;
        users[msg.sender].username = _newName;
        delete userByName[_oldName];
        emit UserRenamed(msg.sender, _newName);
    }

    function removeUser(address _addr) external onlyDriveOwner() userExists(_addr) {
        require(_addr != msg.sender, "Cannot remove owner");
        delete userById[users[_addr].id];
        delete userByName[users[_addr].username];
        delete users[_addr];
        userCount -= 1;
        emit UserRemoved(_addr);
    }

    function viewUserList() external view returns(User[] memory) {
        User[] memory result = new User[](userCount);
        for (uint i = 0; i < userCount; i++) {
            result[i] = users[userById[i]];
        }
        return result;
    }

    function whoami() external view returns (string memory) {
        return users[msg.sender].username;
    }

}

