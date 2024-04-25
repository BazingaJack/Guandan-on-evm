import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";
import { ContractFactory } from "ethers";
import { access } from "../typechain-types/@openzeppelin/contracts";

interface Card {
    cardId: number;
    num: number;
    color: number;
    owner: string;
    status: boolean;
}

describe("Guandan Contract deployed", async function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployContracts() {
        // Contracts are deployed using the first signer/account by default
        const [deployer, player1, player2, player3, player4] = await ethers.getSigners();
        const Guandan = await ethers.getContractFactory("Guandan");
        const guandan = await Guandan.deploy();

        return {
            guandan,
            accounts : {deployer, player1, player2, player3, player4}
        }
    }

    describe("Deploy test",async function () {
        it("Should deploy the contract successfully",async function () {
            const {guandan} = await loadFixture(deployContracts);
            const gameId = await guandan.nextGameId();
            const salt = await guandan.globalSalt();
            const first = await guandan.deck(0);
            const last = await guandan.deck(107);
            expect(gameId).to.be.equal(0);
            expect(salt).to.be.equal(0);
            expect(first).to.be.equal(0);
            expect(last).to.be.equal(107);
        })
    })

    describe("Utils test",async function () {
        it("Should judge Boom card type successfully",async function () {
            const {guandan,accounts} = await loadFixture(deployContracts);
            const cards: Card[] = [
                { cardId: 0, num: 5, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 1, num: 5, color: 1, owner: accounts.player1.address, status: true },
                { cardId: 2, num: 5, color: 2, owner: accounts.player1.address, status: true },
                { cardId: 3, num: 5, color: 3, owner: accounts.player1.address, status: true },
            ];
            const res = await guandan.judgeBoom(cards);
            expect(res).to.be.equal(true);
            cards[0].num = 1;
            const res2 = await guandan.judgeBoom(cards);
            expect(res2).to.be.equal(false);
        })

        it("Should judge Straight card type successfully",async function () {
            const {guandan,accounts} = await loadFixture(deployContracts);
            const cards: Card[] = [
                { cardId: 0, num: 3, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 1, num: 4, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 2, num: 5, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 3, num: 6, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 4, num: 7, color: 0, owner: accounts.player1.address, status: true },
            ];
            const [isValid,isSameColor] = await guandan.judgeStraight(cards);
            expect(isValid).to.be.equal(true);
            expect(isSameColor).to.be.equal(true);
            cards[0].color = 1;
            const [isValid2,isSameColor2] = await guandan.judgeStraight(cards);
            expect(isValid2).to.be.equal(true);
            expect(isSameColor2).to.be.equal(false);
            cards[0].color = 0;
            cards[0].num = 2;
            const [isValid3,isSameColor3] = await guandan.judgeStraight(cards);
            expect(isValid3).to.be.equal(false);
            expect(isSameColor3).to.be.equal(true);
        })

        it("Should judge Triple Pair card type successfully",async function () {
            const {guandan,accounts} = await loadFixture(deployContracts);
            const cards: Card[] = [
                { cardId: 0, num: 2, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 1, num: 2, color: 1, owner: accounts.player1.address, status: true },
                { cardId: 2, num: 3, color: 2, owner: accounts.player1.address, status: true },
                { cardId: 3, num: 3, color: 3, owner: accounts.player1.address, status: true },
                { cardId: 4, num: 4, color: 2, owner: accounts.player1.address, status: true },
                { cardId: 5, num: 4, color: 3, owner: accounts.player1.address, status: true },
            ];
            const res = await guandan.judgeTriplePair(cards);
            expect(res).to.be.equal(true);
            cards[0].num = 1;
            const res2 = await guandan.judgeTriplePair(cards);
            expect(res2).to.be.equal(false);
        })

        it("Should judge Two Triple Single card type successfully",async function () {
            const {guandan,accounts} = await loadFixture(deployContracts);
            const cards: Card[] = [
                { cardId: 0, num: 2, color: 0, owner: accounts.player1.address, status: true },
                { cardId: 1, num: 2, color: 1, owner: accounts.player1.address, status: true },
                { cardId: 2, num: 2, color: 2, owner: accounts.player1.address, status: true },
                { cardId: 3, num: 3, color: 3, owner: accounts.player1.address, status: true },
                { cardId: 4, num: 3, color: 2, owner: accounts.player1.address, status: true },
                { cardId: 5, num: 3, color: 3, owner: accounts.player1.address, status: true },
            ];
            const res = await guandan.judgeTwoTripleSingle(cards);
            expect(res).to.be.equal(true);
            cards[0].num = 1;
            const res2 = await guandan.judgeTwoTripleSingle(cards);
            expect(res2).to.be.equal(false);
        })
    })
});
