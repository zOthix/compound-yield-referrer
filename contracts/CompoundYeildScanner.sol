// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./interface/ICompound.sol";
import "./interface/IERC20.sol";
import "./Users.sol";

contract CompoundYeildScanner {
    IERC20 public erc20Token;
    ICompound public compoundAddress;
    uint256 public feePercentage;
    address public owner;

    mapping(address => address) public userCompoundAddress; // users[userAddress] = compoundAddress;

    constructor(
        address _erc20Address,
        address _compoundAddress,
        uint256 _feePercentage,
        address _owner
    ) {
        erc20Token = IERC20(_erc20Address);
        compoundAddress = ICompound(_compoundAddress);
        feePercentage = _feePercentage;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function supply(uint256 amount) public {

        address userAddress = msg.sender;

        if (address(userCompoundAddress[userAddress]) == address(0)) {
            userCompoundAddress[userAddress] = address(new Users(
                address(compoundAddress),
                address(erc20Token)
            ));
        }

        address userCompoundAddress_ = userCompoundAddress[userAddress];

        erc20Token.transferFrom(userAddress, address(userCompoundAddress_), amount);
        Users(userCompoundAddress_).supplyCompound(amount);
        
    }

    function withdraw(uint amount) public {
        address userAddress = msg.sender;

        if (address(userCompoundAddress[userAddress]) == address(0)) {
            revert("User not found");
        }

        address userCompoundAddress_ = userCompoundAddress[userAddress];

        Users(userCompoundAddress_).withdrawCompound(amount);

        uint256 fee = (amount * feePercentage) / 100;
        uint256 amountAfterFee = amount - fee;
        Users(userCompoundAddress_).transferFunds(userAddress, amountAfterFee);
        Users(userCompoundAddress_).transferFunds(address(this), fee);
    }
    
    function withdrawOwner (uint256 amount) public onlyOwner {
        require(erc20Token.balanceOf(address(this)) >= amount, "Insufficient balance");
        erc20Token.transfer(owner, amount);
    }
    
    function getCompoundAddress(address userAddress) public view returns (address) {
        return address(userCompoundAddress[userAddress]);
    }
}
