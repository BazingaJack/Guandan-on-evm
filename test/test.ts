import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";
import { ContractFactory } from "ethers";

describe("Guandan Contract deployed", async function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployContracts() {
        // Contracts are deployed using the first signer/account by default
        const [deployer] = await ethers.getSigners();
        const Guandan = await ethers.getContractFactory("Guandan");
        const guandan = await Guandan.deploy();

        return {
            guandan,
            accounts : {deployer}
        }
    }

    describe("Function test",async function () {
        it("Should  successfully",async function () {
            const {guandan} = await loadFixture(deployContracts);
            // const tx = await guandan.getNum();
            // const receipt = await tx.wait();
            // const num = receipt.status;
            // expect(num).to.equal(1);
        })
    })
});
