// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRewardTokenContract
 * @author Abe
 * @dev RewardTokenContract interface.
 */

interface IRewardTokenContract is IERC20 {
    function mint(address to, uint256 amount) external;
}
