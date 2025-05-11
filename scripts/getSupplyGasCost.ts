import { ethers } from "hardhat";
import { ARBI_USDC_ADDR, COMPOUND_ARBI_USDC_ADDR } from "../constants";
import { formatUnits } from "ethers";

async function main() {
    console.log("Starting deployment...");

    const signer = (await ethers.getSigners())[0];
    console.log("Signer address:", signer.address);

    // Get unsigned factory and connect to signer explicitly
    const unsignedFactory = await ethers.getContractFactory("Users");
    const userFactory = unsignedFactory.connect(signer);

    const deployTx = await userFactory.getDeployTransaction(
        COMPOUND_ARBI_USDC_ADDR,
        ARBI_USDC_ADDR
    );

    if (!deployTx.data) {
        throw new Error("Missing deployment bytecode. Make sure contract is compiled.");
    }

     const gasEstimate = await signer.estimateGas(deployTx);
     console.log("Estimated gas units:", gasEstimate.toString());
 
     const feeData = await ethers.provider.getFeeData();
     const gasPrice = feeData.gasPrice;
     if (!gasPrice) {
         throw new Error("Failed to retrieve gas price.");
     }
     console.log("Current gas price (wei):", gasPrice.toString());
 
     const totalCostWei = gasEstimate * gasPrice;
 
     const totalCostEth = formatUnits(totalCostWei, "ether");
     console.log(`Estimated total deployment cost in ETH: ${totalCostEth} ETH`);
}

main().catch((error) => {
    console.error("Error during deployment:", error);
    process.exitCode = 1;
});
