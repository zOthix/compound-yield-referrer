import { ethers } from "hardhat";
import { CompoundYeildScanner__factory } from "../typechain-types";
import { ARBI_USDC_ADDR } from "../constants";

const main = async () => {
    try {
        const signer = (await ethers.getSigners())[0];

        const tokenAddress = ARBI_USDC_ADDR; // Replace with your ERC20 token address
        const erc20Abi = [
            "function approve(address spender, uint256 amount) public returns (bool)",
            "function balanceOf(address account) external view returns (uint256)",
            "function allowance(address owner, address spender) external view returns (uint256)"
        ];
        const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, signer);

        const contractAddress = '0x591b83f47BA1e4c6Ba3AbbEF2828BdF7F81f605A'; // Replace with your contract address
        const yeildContract = CompoundYeildScanner__factory.connect(contractAddress, signer);
        const amount = "0.01";

        try {

            const userBalance = await tokenContract.balanceOf(signer.address);
            console.log("User address:", signer.address);
            console.log("User balance:", ethers.formatUnits(await ethers.provider.getBalance(signer.address), 18));

            if (BigInt(userBalance) < (ethers.parseUnits(amount, 6))) {
                console.error("Insufficient balance USDC:", ethers.formatUnits(userBalance, 6));
                console.error("Required amount:", amount);
                throw new Error("Insufficient balance to proceed with the transaction.");
            }

            const approveAmount = ethers.parseUnits("1000", 6);
            const approveTx = await tokenContract.approve(contractAddress, approveAmount);
            console.log("Approval transaction sent:", approveTx.hash);

            // Wait for the approval transaction to be mined
            const approveReceipt = await approveTx.wait();
            console.log("Approval transaction mined:", approveReceipt?.transactionHash);
        } catch (error: any) {
            console.error("Error during approval transaction:", error?.reason || error?.message || error);
            return;
        }

        try {


            const allowance = await tokenContract.allowance(signer.address, contractAddress);
            const supplyAmount = ethers.parseUnits(amount, 6);
            console.log("Allowance:", ethers.formatUnits(allowance, 6));
            console.log("Supply amount:", ethers.formatUnits(supplyAmount, 6));


            const supplyTx = await yeildContract.supply(supplyAmount);
            console.log("Supply Transaction sent:", supplyTx.hash);
            // Wait for the transaction to be mined
            const supplyReceipt = await supplyTx.wait();
            console.log("Supply Transaction mined:", supplyReceipt?.hash);
        } catch (error: any) {
            console.error("Error during supply transaction:", error);
            return;
        }

        try {
            const withdrawAmount = "0.001";
            const tx = await yeildContract.withdraw(ethers.parseUnits(withdrawAmount, 6));
            console.log("Withdraw transaction sent:", tx.hash);
            // Wait for the transaction to be mined
            const receipt = await tx.wait();
            console.log("Withdraw Transaction mined:", receipt?.hash);
        } catch (error: any) {
            console.error("Error during withdraw transaction:", error?.reason || error?.message || error);
            return;
        }

        const userCompoundAddr = await yeildContract.getCompoundAddress(signer.address);
        console.log("User Compound address:", userCompoundAddr);
    } catch (error: any) {
        console.error("Unexpected error:", error?.reason || error?.message || error);
    }
};

main();