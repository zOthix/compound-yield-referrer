import { ethers } from "hardhat";
import { expect } from "chai";
import { CompoundYeildScanner } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";

describe("_calculateWithdrawDetails", () => {
  let scanner: CompoundYeildScanner & {
    deploymentTransaction(): ContractTransactionResponse;
  };

  const AddressZero = "0x0000000000000000000000000000000000000000";
  const feePercentage = 1;

  before(async () => {
    const Scanner = await ethers.getContractFactory("CompoundYeildScanner");
    scanner = await Scanner.deploy(
      AddressZero,
      AddressZero,
      feePercentage,
      AddressZero
    );
  });

  const scenarios = [
    {
      name: "no yield, no fee",
      input: {
        amount: 1000,
        suppliedAmount: 1000,
        totalWithYield: 1000,
        feePercentage: 1
      },
      expected: {
        fee: 0,
        amountAfterFee: 1000,
        suppliedPortionWithdrawn: 1000
      }
    },
    {
      name: "yield present, small fee",
      input: {
        amount: 1000,
        suppliedAmount: 1000,
        totalWithYield: 2000,
        feePercentage: 1
      },
      expected: {
        fee: 5,
        amountAfterFee: 995,
        suppliedPortionWithdrawn: 500
      }
    },
    {
      name: "partial withdraw, large feePercent",
      input: {
        amount: 500,
        suppliedAmount: 1000,
        totalWithYield: 1500,
        feePercentage: 1
      },
      expected: {
        fee: 1,
        amountAfterFee: 499,
        suppliedPortionWithdrawn: 333
      }
    },
    {
      name: "full withdraw with yield, higher fee",
      input: {
        amount: 2000,
        suppliedAmount: 1000,
        totalWithYield: 2000,
        feePercentage: 1
      },
      expected: {
        fee: 10,
        amountAfterFee: 1990,
        suppliedPortionWithdrawn: 1000
      }
    }
  ];

  for (const { name, input, expected } of scenarios) {
    it(`should return correct values for scenario: ${name}`, async () => {
      const [fee, amountAfterFee, suppliedPortionWithdrawn] =
        await scanner._calculateWithdrawDetails(
          input.amount,
          input.suppliedAmount,
          input.totalWithYield,
          input.feePercentage
        );

      expect(fee).to.equal(expected.fee);
      expect(amountAfterFee).to.equal(expected.amountAfterFee);
      expect(suppliedPortionWithdrawn).to.equal(
        expected.suppliedPortionWithdrawn
      );
    });
  }
});
