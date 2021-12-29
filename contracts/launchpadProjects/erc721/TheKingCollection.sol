pragma solidity 0.8.4;

//SPDX-License-Identifier: AGPL-3.0-only
/*
        ,                                                                       
  %%%%%%%%%%%%%%                                                      %%%%%%%   
 %%%           ./    %%                                %%%          %%%       %%
%%%   ,,,,,,         %%,,,,,,.    ,,,      ,    ,,,,   %%%,,,,,,   %%%%%%%%%*   
 %%%       ,,,,,     %%       %%%%%%%%%%   %%%%%%%/    %%%      %%%%%%%%%#    %%
  %%%%%*      ,,,    %%      %%%       %%  %%%         %%%         (%%        %%
      ,%%%%%   ,,,   %%%     %%%       %%  %%%         %%%         (%%        %%
  ,           ,,,     %%%%%%  .%%%%%%% %%  %%%          #%%%%%(    (%%        %%
  ,,,,,,,,,,,,,,                                                                */
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '../../extensions/RandomlyAssigned.sol';
import '../../extensions/WithEthPayment.sol';
import '../../extensions/WithStartTime.sol';
import '../../extensions/PausableNFT.sol';

/// @title  TheKingCollection With Eth contract
//

contract TheKingCollection is
    Initializable,
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable,
    RandomlyAssigned,
    WithStartTime,
    PausableNFT,
    WithEthPayment
{
    /**************************libraries ********** */
    using StringsUpgradeable for uint256;
    /***************************Declarations go here ********** */
    // stat var
    uint256 public revealTime;

    string private _baseTokenURI;

    // tokenID => timestamp
    mapping(uint256 => uint256) private _tokenRevealTime;

    // event

    // modifier
    /******************************************* constructor goes here ********************************************************* */

    function initialize(
        string memory baseTokenURI_,
        uint256 startTimeSale_,
        uint256 mintPrice_,
        uint256 maxSupply_,
        uint256 revealTime_,
        uint256 reserved_,
        address[] memory wallets_,
        address owner_
    ) external initializer {
        __Ownable_init();
        // _transferOwnership(owner_);
        __ERC721_init('The King Vidal Collection', 'KVC');
        _collection_init(baseTokenURI_, revealTime_);
        _randomlyAssigned_init(0);
        _withEthPayment_init(wallets_, mintPrice_);
        _pausableNFT_init(owner_);
        _withStartTime_init(startTimeSale_);
        _withLimitedSupply_init(maxSupply_);
        _withLimitedSupplyAndReserves_init(reserved_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _collection_init(string memory baseTokenURI_, uint256 revealTime_) private {
        _baseTokenURI = baseTokenURI_;
        revealTime = revealTime_;
    }

    /******************************************* read state functions go here ********************************************************* */
    /// @notice this function will throw error if called before time
    /// @return _baseTokenURI the return variables of a contract’s function state variable
    function _baseURI() internal view virtual override returns (string memory) {
        // do we need to force reveal time here ?
        return _baseTokenURI;
    }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual override(ERC721UpgradeableEnumerable) {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    /**
     * @dev See {IERC721UpgradeableMetadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721UpgradeableURIStorage: URI query for nonexistent token');
        require(
            _tokenRevealTime[tokenId] <= block.timestamp,
            'ERC721UpgradeableURIStorage: URI query for non revealed token'
        );

        return super.tokenURI(tokenId);
    }

    /// @param owner_  address of the NFTs' owner
    /// @return Number of NFTs owened by the `owner_`
    function ownerNFTs(address owner_) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner_);
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            for (uint256 index; index < balance; index++) {
                result[index] = tokenOfOwnerByIndex(owner_, index);
            }
            return result;
        }
    }

    /******************************************* modify state functions go here ********************************************************* */

    /// @notice Only woner can call it
    /// @dev  `_to` can't hold more than the `maxToMintPerAddress`
    /// @dev  `_to` can't be empty
    /// @dev  `_numberOfNFTs` can't zero
    /// @dev must not xceed the cap
    /// @param _to NFT holder address
    /// @param _numberOfNFTs number of NFT to be minted
    /// emit Transfer
    function mintReservedNFTs(address _to, uint256 _numberOfNFTs)
        external
        onlyOwner
        isWithinReserveCapLimit(_numberOfNFTs)
    {
        require(_numberOfNFTs > 0, 'invalid_amount');
        require(_to != address(0), 'invalid_address');
        _addToTotalReserveSupply(_numberOfNFTs);

        _batchMint(_to, _numberOfNFTs);
    }

    /// @notice caller should pay the required price
    /// @dev  called only when sale is started
    /// @dev  called only when not paused
    /// @dev  `_numberOfNFTs` can't zero
    /// @dev must not xceed the cap
    /// @param _numberOfNFTs number of NFT to be minted
    /// emit Transfer
    function mint(uint256 _numberOfNFTs) external payable whenNotPaused isSaleStarted {
        require(_numberOfNFTs > 0, 'invalid_amount');
        require(mintPrice() * _numberOfNFTs <= msg.value, 'ETH value not correct');
        _batchMint(_msgSender(), _numberOfNFTs);
    }

    function _batchMint(address to, uint256 _numberOfNFTs) private nonReentrant {
        for (uint256 i = 0; i < _numberOfNFTs; i++) {
            uint256 mintIndex = nextToken();
            if (totalSupply() < maxSupply()) {
                _tokenRevealTime[mintIndex] = block.timestamp + revealTime;
                _safeMint(to, mintIndex);
            }
        }
    }

    /// @notice Only woner can call it
    /// @dev  `_URI` can't be empty
    /// @param _URI new base URI
    function setBaseURI(string memory _URI) external onlyOwner {
        require(bytes(_URI).length > 0, 'Empty base URI is not allowed');
        _baseTokenURI = _URI;
    }

    /// @notice Only woner can call it
    /// @dev  `__startTimeURI` must be more than the current time
    /// @param _startTime new _startTime
    function updateSaleStartTime(uint256 _startTime) external onlyOwner isSaleNotStarted {
        _setSaleStartTime(_startTime);
    }

    /**
     * @dev Withdraw accumulated balance for `wallets`
     *
     */
    function withdraw() external onlyOwner {
        _withdraw();
    }
}
