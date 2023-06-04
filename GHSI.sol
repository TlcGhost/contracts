// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GHSI is ERC20, Ownable {
    uint256 constant maxSupply = 100000000 * (10 ** 18); // 100,000,000 GHSI

    constructor() ERC20('GHSI', 'GHSI') {
        _mint(msg.sender, maxSupply);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    function revokeOwnership() public onlyOwner {
        renounceOwnership();
    }

    function changeOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }
}
