// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";


contract UserSystem {
    
    struct User {
        address addr;
        uint id;
        string name;
    }

    User driveOwner;
    User[] userList;

    mapping(address => User) private users;
    mapping(address => bool) private whitelist;
    mapping(uint => address) private by_id;
    mapping(string => address) private by_name;

    uint public numOfUsers;

    event UserAdded(address indexed _addr);
    
    constructor(string memory _ownerName) {
        driveOwner.addr = msg.sender;
        driveOwner.id = 0;
        driveOwner.name = _ownerName;

        users[msg.sender] = driveOwner;
        whitelist[driveOwner.addr] = true;
        by_id[driveOwner.id] = driveOwner.addr;
        by_name[driveOwner.name] = driveOwner.addr;
        numOfUsers = 1;
    }

    // on whitelist, grant read permission to all files
    function whitelistUser(address _addr) external {
        require(msg.sender == driveOwner.addr, "Only driveOwner can whitelist the user");
        require(!whitelist[_addr], "The address has already been whitelisted");               
        // add user into the userList list
        users[_addr] = User({
            addr: _addr,
            id: numOfUsers,
            name: string.concat("User ", Strings.toString(numOfUsers))
        });
        
        User memory newUser = users[_addr];
        whitelist[_addr] = true;
        by_id[newUser.id] = newUser.addr;
        by_name[newUser.name] = newUser.addr;
        numOfUsers += 1;

        emit UserAdded(_addr);
    }

    function changeSelfUsername(string memory _name) external {
        require(by_name[_name] == address(0), "Name not available");
        require(whitelist[msg.sender], "User does not exist");
        User storage target = users[msg.sender];
        target.name = _name;
    }

    function viewDriveOwner() external view returns(address) {
        return driveOwner.addr;
    }

    function viewWhitelist() external view returns(address[] memory) {
        address[] memory result = new address[](numOfUsers);
        result[0] = driveOwner.addr;
        for (uint i = 1; i < numOfUsers; i++) {
            result[i] = users[by_id[i]].addr;
        }
        return result;
    }

    function viewUsername(address _addr) external view returns(string  memory) {
        require(whitelist[_addr], "User not whitelisted");
        return users[_addr].name;
    }

}

