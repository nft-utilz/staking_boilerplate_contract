// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IStakeSystem
 * @author Abe
 * @dev StakeSystem interface.
 */

interface IStakeSystem {
    /**
     * @notice This struct contains data related to a Staked Tokens
     *
     * @param stackedTokenIds - Array of tokenIds that are staked
     * @param successedTokenIds - Array of tokenIds that are successfully staked
     * @param totalEarndErc20Tokens - Total earned coins
     * @param balance - Total balance of staked tokens
     */

    struct UserInfo {
        uint256[] stackedTokenIds;
        uint256 balance;
        uint256[] successedTokenIds;
        uint256 totalEarnedErc20Tokens;
    }

    /**
     *
     * @param successedNum - Number of successfully staked tokens
     * @param owner - Owner of the token
     * @param isStacked - Whether the token are stacked
     * @param isWithdrawable - Whether the token are withdrawable
     * @param startTime - Start time of the staking
     * @param finishingTime - Finishing time of the staking
     */

    struct StakingTokenInfo {
        uint256 tokenId;
        address owner;
        bool isStacked;
        uint256 startTime;
        uint256 finishingTime;
    }

    function getStakingTokenInfoBatch(address _tokenOwner)
        external
        view
        returns (StakingTokenInfo[] memory);

    function getStakingTokenInfo(uint256 tokenId)
        external
        view
        returns (StakingTokenInfo memory);

    function isWithdrawable(uint256 _tokenId) external view returns (bool);

    function getUserInfo(address _owner)
        external
        view
        returns (UserInfo memory);

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 tokenId);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 tokenId);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 tokenId);
}
