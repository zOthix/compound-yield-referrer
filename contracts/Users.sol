// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./interface/ICompound.sol";
import "./interface/IERC20.sol";

contract Users {
    IERC20 public erc20Token;
    ICompound public compoundAddress;

    constructor( address _compoundAddress, address _erc20Address ) {
        compoundAddress = ICompound(_compoundAddress);
        erc20Token = IERC20(_erc20Address);
    }

    function supplyCompound(uint256 amount) external {
        erc20Token.approve(address(compoundAddress), amount);
        compoundAddress.supply(address(erc20Token), amount);
    }

    function withdrawCompound(uint256 amount) external {
        compoundAddress.withdraw(address(erc20Token), amount);
    }

    function transferFunds(address to, uint256 amount) external {
        erc20Token.transfer(to, amount);
    }
}