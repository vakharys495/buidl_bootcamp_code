// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WereyCoin is ERC20, Ownable, ERC20Permit {
    constructor(address recipient, address initialOwner)
        ERC20("WereyCoin", "WCN")
        Ownable(initialOwner)
        ERC20Permit("WereyCoin")
    {
        _mint(recipient, 100000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
