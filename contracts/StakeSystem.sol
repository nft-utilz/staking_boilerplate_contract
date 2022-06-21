// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IStakeSystem.sol";
import "./interfaces/IRewardTokenContract.sol";

// import ""
// interface IRewardTokenContract is IERC20 {
//     function mint(address to, uint256 amount) external;
// }

contract StakeSystem is ERC721Holder, Ownable, ReentrancyGuard, IStakeSystem {
    IERC721 public nftContract;
    IRewardTokenContract public rewardsTokenContract;

    mapping(uint256 => uint256) public tokenStakedAt;

    mapping(address => uint256) internal balance;
    mapping(address => UserInfo) internal userInfo;
    // mapping(address => IStakeSystem.UserInfo) internal userInfo;
    mapping(uint256 => StakingTokenInfo) internal stakingTokenInfo;
    // mapping(uint256 => IStakeSystem.StakingTokenInfo) internal stakingTokenInfo;

    uint256[] public stakingTokenIds;

    // uint256[] STAKING_TIME_ARR = [1 days, 3 days, 7 days, 10 days, 14 days];
    uint256[] STAKING_TIME_ARR = [1 hours, 2 hours, 3 hours, 4 hours, 5 hours];
    // uint256[] STAKING_TIME_ARR = [1 minutes, 2 minutes, 3 minutes, 4 minutes, 5 minutes];
    // minutes
    uint256 public totalStakingSupply = 0;

    uint256 internal decimals = 18;

    // uint256 public EMISSION_RATE = uint256((50 * 10**decimals) / 1 minutes); //1시간에 50개 코인
    uint256 public EMISSION_RATE = uint256((50 * 10**decimals) / 1 hours); //1시간에 50개 코인

    // uint256 public EMISSION_RATE = uint256((50 * 10**decimals) / 1 days); //하루에 50개 코인

    constructor(address _nftContract, address _rewardsTokenContract) {
        nftContract = IERC721(_nftContract);
        rewardsTokenContract = IRewardTokenContract(_rewardsTokenContract);
        // EMISSION_RATE = uint256((50 * 10**decimals) / 1 days);
    }

    // /// @notice event emitted when a user has staked a nft
    // event Staked(address owner, uint256 tokenId);

    // /// @notice event emitted when a user has unstaked a nft
    // event Unstaked(address owner, uint256 tokenId);

    // /// @notice event emitted when a user claims reward
    // event RewardPaid(address indexed user, uint256 reward);

    // /// @notice Emergency unstake tokens without rewards
    // event EmergencyUnstake(address indexed user, uint256 tokenId);

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(
            ownerOfStakingToken(_tokenId) == msg.sender,
            "Only the token owner can do this"
        );
        _;
    }

    modifier isValidStakingTime(uint256 stakingTime) {
        require(
            stakingTime == 0 ||
                stakingTime == 1 ||
                stakingTime == 2 ||
                stakingTime == 3 ||
                stakingTime == 4,
            "Invalid staking time"
        );
        _;
    }

    function popToken(uint256 _tokenId) internal {
        for (uint256 i = 0; i < stakingTokenIds.length; i++) {
            if (stakingTokenIds[i] == _tokenId) {
                stakingTokenIds[i] = stakingTokenIds[
                    stakingTokenIds.length - 1
                ];
                stakingTokenIds.pop();
            }
        }
    }

    function isWithdrawable(uint256 _tokenId) public view returns (bool) {
        return stakingTokenInfo[_tokenId].finishingTime <= block.timestamp;
    }

    function isWithdrawableBatch(uint256[] memory _tokenIds)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!isWithdrawable(_tokenIds[i])) return false;
        }
        return true;
    }

    function stake(uint256 _tokenId, uint256 stakingTime)
        external
        nonReentrant
        isValidStakingTime(stakingTime)
    {
        require(
            ownerOfStakingToken(_tokenId) == address(0),
            "This token has already been staked"
        );

        // nft.approve(address(this), _tokenId);
        // approve는 여기서 하는거 아니고 원래 nft만든 contract에서 해줘야 하는거야
        // 여기서 safeTransferfrom은 자동으로 approve됐는지 확인해주는 기능이 있어
        // 이거가 자동으로 블락킹해
        // 거래 할때마다 approve해줘야함
        // 우선 approve 됐는지 확인읗 먼저 해야돼
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        stakingTokenInfo[_tokenId].tokenId = _tokenId;
        stakingTokenInfo[_tokenId].owner = msg.sender;
        stakingTokenInfo[_tokenId].startTime = block.timestamp;
        stakingTokenInfo[_tokenId].isStacked = true;
        stakingTokenInfo[_tokenId].finishingTime =
            block.timestamp +
            STAKING_TIME_ARR[stakingTime];
        userInfo[msg.sender].balance += 1;
        totalStakingSupply += 1;
        stakingTokenIds.push(_tokenId);
        emit Staked(msg.sender, _tokenId);
    }

    function calculateTokens(uint256 _tokenId) public view returns (uint256) {
        // uint256 timeElapsed = block.timestamp -
        //     stakingTokenInfo[_tokenId].startTime;
        uint256 timeElapsed = stakingTokenInfo[_tokenId].finishingTime -
            stakingTokenInfo[_tokenId].startTime;
        return timeElapsed * EMISSION_RATE;
    }

    function unstake(uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        nonReentrant
    {
        // checkout if the token staked or not
        require(
            stakingTokenInfo[_tokenId].isStacked,
            "This token is not staked"
        );
        require(isWithdrawable(_tokenId), "This token is not withdrawable");
        userInfo[msg.sender].totalEarnedErc20Tokens += calculateTokens(
            _tokenId
        );
        rewardsTokenContract.mint(msg.sender, calculateTokens(_tokenId));
        nftContract.transferFrom(address(this), msg.sender, _tokenId);
        delete stakingTokenInfo[_tokenId];
        userInfo[msg.sender].balance -= 1;
        totalStakingSupply -= 1;
        popToken(_tokenId);
        emit Unstaked(msg.sender, _tokenId);
    }

    function emergencyUnstake(uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        nonReentrant
    {
        require(!isWithdrawable(_tokenId), "This token is withdrawable");
        nftContract.transferFrom(address(this), msg.sender, _tokenId);
        delete stakingTokenInfo[_tokenId];
        userInfo[msg.sender].balance -= 1;
        userInfo[msg.sender].successedTokenIds.push(_tokenId);
        totalStakingSupply -= 1;
        popToken(_tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    function claimToken(uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        nonReentrant
    {
        require(isWithdrawable(_tokenId), "The token is not withdrawable");
        // _mint(msg.sender, calculateTokens(_tokenId)); // Minting the tokens for staking
        rewardsTokenContract.mint(msg.sender, calculateTokens(_tokenId));
        // rewardsTokenContract.mint(msg.sender, calculateTokens(_tokenId));

        // uint256[] STAKING_TIME_ARR = [1 days, 3 days, 7 days, 10 days, 14 days];
        uint256 prevTimeGap = stakingTokenInfo[_tokenId].finishingTime -
            stakingTokenInfo[_tokenId].startTime;

        stakingTokenInfo[_tokenId].startTime = block.timestamp;

        stakingTokenInfo[_tokenId].finishingTime =
            block.timestamp +
            prevTimeGap;
        emit RewardPaid(msg.sender, calculateTokens(_tokenId));
    }

    function claimTokenBatch(uint256[] memory _tokenIds) external nonReentrant {
        require(
            isWithdrawableBatch(_tokenIds),
            "The token is not withdrawable"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                ownerOfStakingToken(_tokenIds[i]) == msg.sender,
                "Only the token owner can do this"
            );
        }

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalTokens += calculateTokens(_tokenIds[i]);
        }
        // _mint(msg.sender, totalTokens); // Minting the tokens for staking
        rewardsTokenContract.mint(msg.sender, totalTokens);
        // rewardsTokenContract.mint(msg.sender, totalTokens);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 prevTimeGap = stakingTokenInfo[_tokenIds[i]].finishingTime -
                stakingTokenInfo[_tokenIds[i]].startTime;

            stakingTokenInfo[_tokenIds[i]].startTime = block.timestamp;

            stakingTokenInfo[_tokenIds[i]].finishingTime =
                block.timestamp +
                prevTimeGap;
        }
        emit RewardPaid(msg.sender, totalTokens);
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        require(_owner != address(0), "Invalid owner");
        // uint256[] memory tokens;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = stakingBalanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
            // 일단 여기서 오류날꺼 빼박이긴 한데 일단 돌려고보 없애자
            if (ownerOfStakingToken(i) != address(0)) {
                currOwnershipAddr = ownerOfStakingToken(i);
            }

            if (ownerOfStakingToken(i) == address(0)) {
                currOwnershipAddr = address(0);
            }

            if (currOwnershipAddr == _owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }

    function stakingBalanceOf(address _owner) public view returns (uint256) {
        return userInfo[_owner].balance;
        // return balance[account];
    }

    function getTotalStakingTokenIds() public view returns (uint256[] memory) {
        uint256 tokenIdsLength = stakingTokenIds.length;
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        uint256 tokenIdsIdx = 0;
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            if (ownerOfStakingToken(stakingTokenIds[i]) != address(0)) {
                tokenIds[tokenIdsIdx++] = stakingTokenIds[i];
            }
        }
        return tokenIds;
    }

    function getStakingTokenTimes(uint256 tokenId)
        public
        view
        returns (uint256[2] memory)
    {
        return [
            stakingTokenInfo[tokenId].startTime,
            stakingTokenInfo[tokenId].finishingTime
        ];
    }

    function getStakingTokenInfo(uint256 tokenId)
        public
        view
        returns (StakingTokenInfo memory)
    {
        return stakingTokenInfo[tokenId];
    }

    function getStakingTokenInfoBatch(address _owner)
        public
        view
        returns (StakingTokenInfo[] memory)
    {
        uint256[] memory tokenIds = tokensOfOwner(_owner);
        uint256 tokenIdsLength = tokenIds.length;
        IStakeSystem.StakingTokenInfo[]
            memory stakingTokenInfoBatch = new IStakeSystem.StakingTokenInfo[](
                tokenIdsLength
            );
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            stakingTokenInfoBatch[i] = getStakingTokenInfo(tokenIds[i]);
        }
        return stakingTokenInfoBatch;
    }

    function ownerOfStakingToken(uint256 tokenId)
        public
        view
        returns (address)
    {
        return stakingTokenInfo[tokenId].owner;
    }

    function getUserInfo(address _owner) public view returns (UserInfo memory) {
        return userInfo[_owner];
    }
}
