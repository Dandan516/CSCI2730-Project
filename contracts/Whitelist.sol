// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract Whitelist {
    
    struct User {
        address addr;
        uint id;
        string name;
    }

    User owner;
    User[] users;

    mapping(address => User) get_user;
    mapping(address => bool) whitelist;
    mapping(uint => address) by_id;
    mapping(string => address) by_name;

    uint public num_of_users;
    
    constructor(string memory _owner_name) {
        owner.addr = msg.sender;
        owner.id = 0;
        owner.name = _owner_name;

        get_user[msg.sender] = owner;
        whitelist[owner.addr] = true;
        by_id[owner.id] = owner.addr;
        by_name[owner.name] = owner.addr;
        num_of_users = 1;
    }
    
    event User_whitelisted(address indexed _addr);

    // on whitelist, grant read permission to all files
    function whitelist_user(address _addr) external {
        require(msg.sender == owner.addr, "Only owner can whitelist the user");
        require(!whitelist[_addr], "The address has already been whitelisted");               
        // add user into the users list
        User storage user = get_user[_addr];
        user.addr = _addr;
        user.id = num_of_users;
        user.name = string.concat("User ", Strings.toString(user.id));

        whitelist[_addr] = true;
        by_id[user.id] = user.addr;
        by_name[user.name] = user.addr;
        num_of_users += 1;

        emit User_whitelisted(_addr);
    }

    function change_name(string memory _name) external {
        require(by_name[_name] == address(0), "Name not available");
        require(whitelist[msg.sender], "User not whitelisted");
        User storage target = get_user[msg.sender];
        target.name = _name;
    }

    function check_owner() external view returns(address) {
        return owner.addr;
    }

    function check_whitelist() external view returns(address[] memory) {
        address[] memory result = new address[](num_of_users);
        result[0] = owner.addr;
        for (uint i = 1; i < num_of_users; i++) {
            result[i] = get_user[by_id[i]].addr;
        }
        return result;
    }

    function check_name(address _addr) external view returns(string  memory) {
        require(whitelist[_addr], "User not whitelisted");
        return get_user[_addr].name;
    }

}

