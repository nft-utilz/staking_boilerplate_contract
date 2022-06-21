// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// 0x4132bC5De56e44Fb08B40C996bb25a81a0B64b89
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("RewardToken", "MTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    // function burn(address to, uint256 amount) public onlyRole(MINTER_ROLE){
    //     _burn(to, amount);
    // }

    function getDecimals() public view returns (uint256) {
        return decimals();
    }
}
