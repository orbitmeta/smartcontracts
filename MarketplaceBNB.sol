// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/TypeConversion.sol";

/**
 * @dev MarketplaceBNB for exchange NFTs.
 * If a seller wants to sell his tokens, he should call
 * `NFT.safeTransferFrom`,
 * which transfer his token to our marketplaceBNB.
 *
 * If the seller wants to cancel his offer, he can call `cancelOffer`, which
 * revokes his previous approval.
 *
 * If a buyer wants to buy a token, he should call
 * `MarketplaceBNB.purchase`, which allows our marketplaceBNB to transfer
 * his BNB to the seller.
 */
contract MarketplaceBNB is IERC721Receiver, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC721 private _itemToken;

    struct Trade {
        address owner;
        uint256 price;
        bool isForSale;
    }

    mapping(uint256 => Trade) private _trades;

    event OfferCreated(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event OfferCanceled(address indexed seller, uint256 indexed tokenId);
    /**
     * Event for token purchase logging
     * @param buyer who got the tokens
     * @param tokenId ID of token purchased
     */
    event TokenPurchased(address indexed buyer, uint256 indexed tokenId);

    constructor(address itemTokenAddress_) {
        require(
            itemTokenAddress_ != address(0),
            "Marketplace: token address must not be 0"
        );
        _itemToken = IERC721(itemTokenAddress_);
    }

    function purchase(uint256 tokenId)
        external
        payable
        isListed(tokenId)
        nonReentrant
    {
        Trade memory token = _trades[tokenId];
        require(
            token.owner != msg.sender,
            "MarketplaceBNB: buyer is the owner"
        );
        require(
            msg.value == token.price,
            "MarketplaceBNB: must pay exactly the price"
        );
        address payable seller = payable(token.owner);

        _resetTradingInfo(tokenId);

        // transfer money
        (bool success, ) = seller.call{value: msg.value}("");

        require(success, "Failed to send Ether");
        // transfer NFT
        _itemToken.safeTransferFrom(address(this), msg.sender, tokenId);

        emit TokenPurchased(msg.sender, tokenId);
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory data
    ) external returns (bytes4) {
        uint256 price = TypeConversion.bytesToUint256(data);
        _openOffer(_from, _tokenId, price);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _updateTradingInfo(
        uint256 tokenId,
        address owner,
        uint256 price,
        bool isForSale_
    ) private {
        Trade storage token = _trades[tokenId];
        token.owner = owner;
        token.price = price;
        token.isForSale = isForSale_;
    }

    function _resetTradingInfo(uint256 tokenId) private {
        _updateTradingInfo(tokenId, address(0), 0, false);
    }

    function _openOffer(
        address owner,
        uint256 tokenId,
        uint256 price
    ) private isNotListed(tokenId) nonReentrant {
        require(
            msg.sender == address(_itemToken),
            "MarketplaceBNB: unsupported token"
        );

        _updateTradingInfo(tokenId, owner, price, true);

        emit OfferCreated(owner, tokenId, price);
    }

    function cancelOffer(uint256 tokenId)
        public
        isListed(tokenId)
        nonReentrant
    {
        Trade memory token = _trades[tokenId];
        require(
            token.owner == msg.sender,
            "MarketplaceBNB: caller is not the owner"
        );

        _resetTradingInfo(tokenId);

        _itemToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit OfferCanceled(msg.sender, tokenId);
    }

    function isForSale(uint256 tokenId) public view returns (bool) {
        Trade memory token = _trades[tokenId];
        return token.isForSale;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        isListed(tokenId)
        returns (address)
    {
        Trade memory token = _trades[tokenId];
        return token.owner;
    }

    function priceOf(uint256 tokenId)
        public
        view
        isListed(tokenId)
        returns (uint256)
    {
        Trade memory token = _trades[tokenId];
        return token.price;
    }

    modifier isListed(uint256 tokenId) {
        Trade memory token = _trades[tokenId];
        require(
            token.isForSale == true,
            "MarketplaceBNB: token is not for sale"
        );
        address currentOwner = _itemToken.ownerOf(tokenId);
        require(
            currentOwner == address(this),
            "MarketplaceBNB (sanity check): token is not available on marketplace"
        );
        _;
    }

    modifier isNotListed(uint256 tokenId) {
        Trade memory token = _trades[tokenId];
        require(
            token.isForSale == false,
            "MarketplaceBNB: token is already for sale"
        );
        _;
    }
}
