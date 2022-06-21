// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// 0xc7420ab53DE11e080f4Da48525FEc973f1c9E2cE

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// 최종적으로 이거 사용하기
contract MyNFT is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    bytes32 public root;
    uint256 public maxSupply;

    mapping(address => uint256) public _presaleClaimed;

    // 1 ether = 1000000000000000000
    uint256 public presalePrice;
    uint256 public publicSalePrice;
    string public baseExtension = ".json";
    // string public notRevealedURI = "put your not revealed URI here";
    // example
    string internal notRevealedURI =
        "https://gateway.pinata.cloud/ipfs/QmcXG9QgbBocXuXHA3HukSDGF9aAEi88niNMspwvqRmaNp";

    string internal baseURI;

    uint256 presaleAmountLimit = 15;
    uint256 public maxMintAmountPerTx = 10;

    bool public revealed = false;
    bool public paused = false;
    bool public presaleM = false;
    bool public publicM = false;

    constructor() ERC721A("_name BAYC", "_symbol BAYC") ReentrancyGuard() {
        setPublicSalePrice(1 * 10**16);
        setPresale(1 * 7 * 10**15);
        maxSupply = 100;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _price, uint256 _mintAmount) {
        require(msg.value >= _price * _mintAmount, "Not ennough ether!");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _merkleProof) {
        require(
            MerkleProof.verify(
                _merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "Not allowed origin"
        );
        _;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPublicSalePrice(uint256 _cost) public onlyOwner {
        publicSalePrice = _cost;
    }

    function setPresale(uint256 _cost) public onlyOwner {
        presalePrice = _cost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function getURI(string memory _uri, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bool invalid = bytes(_uri).length < 0;
        string memory _toString = Strings.toString(tokenId);

        if (invalid)
            return string(abi.encodePacked("/", _toString, baseExtension));

        return string(abi.encodePacked(_uri, "/", _toString, baseExtension));
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) return getURI(notRevealedURI, _tokenId);
        string memory currentBaseURI = _baseURI();
        return getURI(currentBaseURI, _tokenId);
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function publicSaleMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(publicSalePrice, _mintAmount)
    {
        require(!paused, "MyNFT: Contract is paused");
        require(publicM, "MyNFT: The public sale is not enabled!");
        _safeMint(msg.sender, _mintAmount);
    }

    function presaleMint(
        address account,
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(presalePrice, _mintAmount)
        isValidMerkleProof(_merkleProof)
    {
        require(msg.sender == account, "MyNFT:  Not allowed");
        require(!paused, "MyNFT: Contract is paused");
        require(presaleM, "MyNFT: Presale is OFF");
        require(
            _presaleClaimed[msg.sender] + _mintAmount <= presaleAmountLimit,
            "MyNFT: You can't mint so much tokens"
        );

        _presaleClaimed[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // 특정 숫자가 되면 예를들어서

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view onlyOwner returns (string memory) {
        return baseURI;
    }

    function airdrop(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded!");
        _safeMint(_to, _amount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        root = _merkleRoot;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
