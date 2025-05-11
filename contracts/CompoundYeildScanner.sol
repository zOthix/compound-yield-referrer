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

    mapping(address => address) public userCompoundAddress;
    mapping(address => uint256) public suppliedAmmount;

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
            userCompoundAddress[userAddress] = address(
                new Users(address(compoundAddress), address(erc20Token))
            );
        }

        address userCompoundAddress_ = userCompoundAddress[userAddress];

        erc20Token.transferFrom(
            userAddress,
            address(userCompoundAddress_),
            amount
        );
        Users(userCompoundAddress_).supplyCompound(amount);
        suppliedAmmount[userCompoundAddress_] += amount;
    }

    function _calculateWithdrawDetails(
        uint256 _amount,
        uint256 _suppliedAmount,
        uint256 _totalWithYield,
        uint256 _feePercentage
    )
        public
        pure
        returns (
            uint256 fee,
            uint256 amountAfterFee,
            uint256 suppliedPortionWithdrawn
        )
    {
        uint256 yield = _totalWithYield - _suppliedAmount;

        fee = (_amount * yield * _feePercentage) / (_totalWithYield * 100);
        amountAfterFee = _amount - fee;

        suppliedPortionWithdrawn =
            (_amount * _suppliedAmount) /
            _totalWithYield;
    }

    function withdraw(uint256 _amount) external {
        address userAddress = msg.sender;

        address userCompound = userCompoundAddress[userAddress];
        if (userCompound == address(0)) {
            revert("User not found");
        }

        uint256 suppliedAmount = suppliedAmmount[userCompound];
        uint256 totalWithYield = compoundAddress.balanceOf(userCompound);

        require(
            _amount <= totalWithYield,
            "Amount exceeds total with yield"
        );

        (
            uint256 fee,
            uint256 amountAfterFee,
            uint256 suppliedPortionWithdrawn
        ) = _calculateWithdrawDetails(
                _amount,
                suppliedAmount,
                totalWithYield,
                feePercentage
            );

        // Update user's remaining supply
        suppliedAmmount[userCompound] =
            suppliedAmount -
            suppliedPortionWithdrawn;

        // Withdraw tokens from Compound
        Users(userCompound).withdrawCompound(_amount);

        // Transfer post-fee amount to user and fee to contract
        Users(userCompound).transferFunds(userAddress, amountAfterFee);
        Users(userCompound).transferFunds(address(this), fee);
    }

    function withdrawOwner(uint256 amount) public onlyOwner {
        require(
            erc20Token.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        erc20Token.transfer(owner, amount);
    }

    function getCompoundAddress(
        address userAddress
    ) public view returns (address) {
        return address(userCompoundAddress[userAddress]);
    }
}
