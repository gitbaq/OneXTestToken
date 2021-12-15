//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract OneXTBBH is ERC20PresetMinterPauser {
    using SafeMath for uint256;

    constructor(uint256 initialSupply)
        ERC20PresetMinterPauser("OneX Test Token", "ONEXT")
    {
        _mint(msg.sender, initialSupply);
    }

    // function transfer(address recipient, uint256 amount) public returns (bool) {
    //   emit TransferEvent(recipient, amount);
    //   _transfer(_msgSender(), recipient, amount);
    //   return true;
    // }
}
