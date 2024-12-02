const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ElectionSystem", function () {
    let ElectionSystem;
    let electionSystem;
    let owner;
    let voter1;
    let voter2;
    let voter3;
    let nonVoter;

    const NAME = "VoteNFT";
    const SYMBOL = "VOTE";
    const BASE_URI = "https://api.vote-nft.com/metadata/";

    beforeEach(async function () {
        // Déploiement du contrat
        [owner, voter1, voter2, voter3, nonVoter] = await ethers.getSigners();
        ElectionSystem = await ethers.getContractFactory("ElectionSystem");
        electionSystem = await ElectionSystem.deploy(NAME, SYMBOL, BASE_URI);
        await electionSystem.deployed();
    });

    describe("Initialisation", function () {
        it("Devrait initialiser correctement le contrat", async function () {
            expect(await electionSystem.name()).to.equal(NAME);
            expect(await electionSystem.symbol()).to.equal(SYMBOL);
            expect(await electionSystem.hasRole(await electionSystem.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
        });
    });

    describe("Gestion des votants", function () {
        it("Devrait permettre d'ajouter un votant", async function () {
            await electionSystem.addVoter(voter1.address);
            expect(await electionSystem.isVoter(voter1.address)).to.be.true;
        });

        it("Devrait permettre d'ajouter plusieurs votants", async function () {
            const voters = [voter1.address, voter2.address, voter3.address];
            await electionSystem.addVoters(voters);
            
            expect(await electionSystem.isVoter(voter1.address)).to.be.true;
            expect(await electionSystem.isVoter(voter2.address)).to.be.true;
            expect(await electionSystem.isVoter(voter3.address)).to.be.true;
            expect(await electionSystem.getVotersCount()).to.equal(3);
        });

        it("Devrait permettre de supprimer un votant", async function () {
            await electionSystem.addVoter(voter1.address);
            await electionSystem.removeVoter(voter1.address);
            expect(await electionSystem.isVoter(voter1.address)).to.be.false;
        });

        it("Ne devrait pas permettre à un non-admin d'ajouter un votant", async function () {
            await expect(
                electionSystem.connect(voter1).addVoter(voter2.address)
            ).to.be.revertedWith(/AccessControl/);
        });
    });

    describe("Gestion des résolutions", function () {
        it("Devrait créer une résolution", async function () {
            const startTime = await time.latest() + 3600; // Dans 1 heure
            const endTime = startTime + 3600; // Durée de 1 heure

            await electionSystem.createResolution(
                "Test Resolution",
                startTime,
                endTime
            );

            expect(await electionSystem.resolutionCounter()).to.equal(1);
        });

        it("Ne devrait pas créer une résolution avec des timestamps invalides", async function () {
            const startTime = await time.latest() - 3600; // Dans le passé
            const endTime = startTime + 3600;

            await expect(
                electionSystem.createResolution("Test Resolution", startTime, endTime)
            ).to.be.revertedWith("Start time must be in the future");
        });

        it("Devrait activer une résolution", async function () {
            const startTime = await time.latest() + 3600;
            const endTime = startTime + 3600;

            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(1);
            
            const resolution = await electionSystem.resolutions(1);
            expect(resolution.status).to.equal(1); // ACTIVE
        });
    });

    describe("Processus de vote", function () {
        let resolutionId;
        let startTime;
        let endTime;

        beforeEach(async function () {
            startTime = await time.latest() + 3600;
            endTime = startTime + 3600;

            await electionSystem.addVoter(voter1.address);
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            resolutionId = 1;
            await electionSystem.activateResolution(resolutionId);
        });

        it("Devrait permettre de voter", async function () {
            await time.increaseTo(startTime);

            await electionSystem.connect(voter1).vote(resolutionId, 1); // POUR

            const resolution = await electionSystem.resolutions(resolutionId);
            expect(resolution.votePour).to.equal(1);
            expect(await electionSystem.balanceOf(voter1.address)).to.equal(1);
        });

        it("Ne devrait pas permettre de voter deux fois", async function () {
            await time.increaseTo(startTime);

            await electionSystem.connect(voter1).vote(resolutionId, 1);
            await expect(
                electionSystem.connect(voter1).vote(resolutionId, 1)
            ).to.be.revertedWith("Already voted");
        });

        it("Ne devrait pas permettre de voter après la fin", async function () {
            await time.increaseTo(endTime + 1);

            await expect(
                electionSystem.connect(voter1).vote(resolutionId, 1)
            ).to.be.revertedWith("Voting has ended");
        });
    });

    describe("Fonctions de pause", function () {
        it("Devrait permettre de mettre en pause et reprendre", async function () {
            await electionSystem.pause();
            expect(await electionSystem.paused()).to.be.true;

            await electionSystem.unpause();
            expect(await electionSystem.paused()).to.be.false;
        });

        it("Ne devrait pas permettre de voter pendant la pause", async function () {
            const startTime = await time.latest() + 3600;
            const endTime = startTime + 3600;

            await electionSystem.addVoter(voter1.address);
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(1);
            await electionSystem.pause();

            await time.increaseTo(startTime);

            await expect(
                electionSystem.connect(voter1).vote(1, 1)
            ).to.be.revertedWith("Pausable: paused");
        });
    });
});
