// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

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

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external returns (bool);
}

interface ICompound {
    function supply(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;
}

contract CompoundYeildScanner {
    IERC20 public erc20Token;
    ICompound public compoundAddress;
    uint256 public feePercentage;

    mapping(address => address) public userCompoundAddress; // users[userAddress] = compoundAddress;

    constructor(
        address _erc20Address,
        address _compoundAddress,
        uint256 _feePercentage
    ) {
        erc20Token = IERC20(_erc20Address);
        compoundAddress = ICompound(_compoundAddress);
        feePercentage = _feePercentage;
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

    function getCompoundAddress(address userAddress) public view returns (address) {
        return address(userCompoundAddress[userAddress]);
    }
}
