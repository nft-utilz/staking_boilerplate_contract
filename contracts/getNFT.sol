// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// 0xc6c8d42bDfeb65a6016ECae90f4843d0a509Bb97
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";
import "./interfaces/IStakeSystem.sol";

// UtilContract
contract GetNFT {
    IERC721AQueryable public nftContract;
    IStakeSystem public stakeContract;

    constructor(address _nftContract, address _stakeContractAddress) {
        nftContract = IERC721AQueryable(_nftContract);
        stakeContract = IStakeSystem(_stakeContractAddress);
    }

    struct TokenInfo {
        uint256 tokenId;
        address isApprovedAddress;
    }

    function getApprovedBatch(address _tokenOwner)
        public
        view
        returns (TokenInfo[] memory)
    {
        uint256[] memory tokenIds = nftContract.tokensOfOwner(_tokenOwner);
        uint256 tokenlength = tokenIds.length;
        TokenInfo[] memory _approvedTokens = new TokenInfo[](tokenlength);
        for (uint256 i = 0; i < tokenlength; i++) {
            _approvedTokens[i].isApprovedAddress = nftContract.getApproved(
                tokenIds[i]
            );
            _approvedTokens[i].tokenId = tokenIds[i];
        }
        return _approvedTokens;
    }

    function isWithdrawableBatch(uint256[] memory _tokenIds)
        public
        view
        returns (bool)
    {
        bool _status = true;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakeContract.getStakingTokenInfo(_tokenIds[i]).isStacked,
                "Token not found"
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!stakeContract.isWithdrawable(_tokenIds[i])) _status = false;
        }
        return _status;
    }

    function getUserInfoBatch(address[] memory wallets)
        public
        view
        returns (IStakeSystem.UserInfo[] memory)
    {
        IStakeSystem.UserInfo[] memory _userInfo = new IStakeSystem.UserInfo[](
            wallets.length
        );
        for (uint256 i = 0; i < wallets.length; i++) {
            _userInfo[i] = stakeContract.getUserInfo(wallets[i]);
        }
        return _userInfo;
    }
}
