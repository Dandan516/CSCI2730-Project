// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract UserSystem {
    
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
    
    event UserAdded(address indexed _addr);

    // on whitelist, grant read permission to all files
    function add_user(address _addr) external {
        require(msg.sender == owner.addr, "Only owner can whitelist the user");
        require(!whitelist[_addr], "The address has already been whitelisted");               
        // add user into the users list
        get_user[_addr] = User({
            addr: _addr,
            id: num_of_users,
            name: string.concat("User ", Strings.toString(num_of_users))
        });
        
        User memory new_user = get_user[_addr];
        whitelist[_addr] = true;
        by_id[new_user.id] = new_user.addr;
        by_name[new_user.name] = new_user.addr;
        num_of_users += 1;

        emit UserAdded(_addr);
    }

    function change_username(string memory _name) external {
        require(by_name[_name] == address(0), "Name not available");
        require(whitelist[msg.sender], "User does not exist");
        User storage target = get_user[msg.sender];
        target.name = _name;
    }

    function check_owner() external view returns(address) {
        return owner.addr;
    }

    function view_whitelist() external view returns(address[] memory) {
        address[] memory result = new address[](num_of_users);
        result[0] = owner.addr;
        for (uint i = 1; i < num_of_users; i++) {
            result[i] = get_user[by_id[i]].addr;
        }
        return result;
    }

    function get_username(address _addr) external view returns(string  memory) {
        require(whitelist[_addr], "User not whitelisted");
        return get_user[_addr].name;
    }

}

