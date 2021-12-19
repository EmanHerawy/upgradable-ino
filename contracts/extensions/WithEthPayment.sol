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

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

/// @title  WithEthPayment contract
//
/// @author startfi team : Eman herawy
contract WithEthPayment is ReentrancyGuardUpgradeable {
    /**************************libraries ********** */
    using AddressUpgradeable for address payable;
    /***************************Declarations go here ********** */
    // stat var

    address[] private _wallets;

    // event
    event Withdrawn(address payee, uint256 amount);

    // modifier
    /******************************************* constructor goes here ********************************************************* */
    function _withEthPayment_init(address[] memory wallets_) internal{
        _wallets = wallets_;
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* modify state functions go here ********************************************************* */

    function getWallets() external view returns (address[] memory) {
        return _wallets;
    }

    /**
     * @dev Withdraw accumulated balance for a wallet 1 and wallet 2, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     */
    function _withdraw() internal virtual nonReentrant {
        uint256 share = address(this).balance / _wallets.length;
        require(share > 0, "Can't split zero shares");
        for (uint256 index = 0; index < _wallets.length; index++) {
            emit Withdrawn(_wallets[index], share);
            payable(_wallets[index]).sendValue(share);
        }
    }
}
