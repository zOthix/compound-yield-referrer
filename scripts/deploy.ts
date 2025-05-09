import { ethers } from "hardhat";
import { ARBI_USDC_ADDR, COMPOUND_ARBI_USDC_ADDR } from "../constants";

async function main() {
  console.log("Starting deployment...");

  // Get the contract factory
  const signer = (await ethers.getSigners())[0];
  console.log("Signer address:", signer.address);
  const CompoundYeildScanner = await ethers.getContractFactory("CompoundYeildScanner" );
  CompoundYeildScanner.connect(signer);

  // Deploy the contract
  const feePercentage = 1;
  const compoundYeildScanner = await CompoundYeildScanner.deploy(
    ARBI_USDC_ADDR, COMPOUND_ARBI_USDC_ADDR, feePercentage, signer.address
  );

  // Wait for the deployment to complete
  await compoundYeildScanner.waitForDeployment();

  console.log("CompoundYeildScanner deployed to:", compoundYeildScanner.target.toString());
}

main().catch((error) => {
  console.error("Error during deployment:", error);
  process.exitCode = 1;
});