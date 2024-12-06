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
    User public currentUser;
    uint public userCount;
    uint internal idCount;
    mapping(address => User) public users;
    mapping(uint => address) internal byId;
    mapping(string => address) internal byName;

    event UserAdded(address indexed addr);
    event UserRenamed(address indexed addr, string newName);
    event UserRemoved(address indexed _addr);


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
        byId[driveOwner.id] = driveOwner.addr;
        byName[driveOwner.username] = driveOwner.addr;
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
        byId[newUser.id] = newUser.addr;
        byName[newUser.username] = newUser.addr;
        userCount += 1;
        idCount += 1;
        emit UserAdded(_addr);
    }

    function renameSelf(string memory _newName) external {
        require(byName[_newName] == address(0), "Name not available");
        string memory _oldName = users[msg.sender].username;
        users[msg.sender].username = _newName;
        delete byName[_oldName];
        emit UserRenamed(msg.sender, _newName);
    }

    function removeUser(address _addr) onlyDriveOwner userExists(_addr) external {
        require(_addr != msg.sender, "Cannot remove owner");
        delete byId[users[_addr].id];
        delete byName[users[_addr].username];
        delete users[_addr];
        userCount -= 1;
        emit UserRemoved(_addr);
    }

    function viewUserList() external view returns(User[] memory) {
        User[] memory result = new User[](userCount);
        for (uint i = 0; i < userCount; i++) {
            result[i] = users[byId[i]];
        }
        return result;
    }

}

