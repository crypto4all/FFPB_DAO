const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ElectionSystem", function () {
    let electionSystem;
    let owner;
    let voter1;
    let voter2;
    let voter3;
    let nonVoter;
    
    const name = "VoteNFT";
    const symbol = "VOTE";
    const baseURI = "https://example.com/token/";

    beforeEach(async function () {
        [owner, voter1, voter2, voter3, nonVoter] = await ethers.getSigners();
        
        const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
        electionSystem = await ElectionSystem.deploy(name, symbol, baseURI);
        await electionSystem.waitForDeployment();
    });

    describe("Initialisation", function () {
        it("Devrait correctement initialiser le contrat", async function () {
            expect(await electionSystem.name()).to.equal(name);
            expect(await electionSystem.symbol()).to.equal(symbol);
            expect(await electionSystem.getVotersCount()).to.equal(0);
        });
    });

    describe("Gestion des votants", function () {
        it("Devrait permettre d'ajouter un votant", async function () {
            await electionSystem.addVoter(voter1.address);
            expect(await electionSystem.getVotersCount()).to.equal(1);
            expect(await electionSystem.hasRole(await electionSystem.VOTER_ROLE(), voter1.address)).to.be.true;
        });

        it("Devrait permettre d'ajouter plusieurs votants", async function () {
            await electionSystem.addVoters([voter1.address, voter2.address, voter3.address]);
            expect(await electionSystem.getVotersCount()).to.equal(3);
        });

        it("Devrait permettre de supprimer un votant", async function () {
            await electionSystem.addVoter(voter1.address);
            await electionSystem.removeVoter(voter1.address);
            expect(await electionSystem.getVotersCount()).to.equal(0);
            expect(await electionSystem.hasRole(await electionSystem.VOTER_ROLE(), voter1.address)).to.be.false;
        });

        it("Ne devrait pas permettre d'ajouter une adresse nulle", async function () {
            await expect(electionSystem.addVoter(ethers.ZeroAddress))
                .to.be.revertedWith("Adresse nulle non autorisee");
        });

        it("Ne devrait pas permettre d'ajouter un votant déjà existant", async function () {
            await electionSystem.addVoter(voter1.address);
            await expect(electionSystem.addVoter(voter1.address))
                .to.be.revertedWith("Deja un votant");
        });
    });

    describe("Gestion des résolutions", function () {
        it("Devrait créer une résolution", async function () {
            const startTime = await time.latest() + 3600; // Dans 1 heure
            const endTime = startTime + 3600; // Durée de 1 heure
            
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            
            const resolution = await electionSystem.getResolutionDetails(0);
            expect(resolution.description).to.equal("Test Resolution");
            expect(resolution.startTime).to.equal(startTime);
            expect(resolution.endTime).to.equal(endTime);
            expect(resolution.status).to.equal(0); // DRAFT
        });

        it("Devrait activer une résolution", async function () {
            const startTime = await time.latest() + 3600;
            const endTime = startTime + 3600;
            
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(0);
            
            const resolution = await electionSystem.getResolutionDetails(0);
            expect(resolution.status).to.equal(1); // ACTIVE
        });

        it("Devrait clôturer une résolution", async function () {
            const startTime = await time.latest() + 3600;
            const endTime = startTime + 3600;
            
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(0);
            await electionSystem.closeResolution(0);
            
            const resolution = await electionSystem.getResolutionDetails(0);
            expect(resolution.status).to.equal(2); // CLOSED
        });
    });

    describe("Système de vote", function () {
        beforeEach(async function () {
            await electionSystem.addVoter(voter1.address);
            const startTime = await time.latest() + 100;
            const endTime = startTime + 3600;
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(0);
            await time.increase(100); // Avance le temps pour commencer la période de vote
        });

        it("Devrait permettre de voter", async function () {
            await electionSystem.connect(voter1).vote(0, 1); // Vote FOR
            
            const resolution = await electionSystem.getResolutionDetails(0);
            expect(resolution.votesFor).to.equal(1);
            expect(await electionSystem.balanceOf(voter1.address)).to.equal(1); // Vérifie le NFT
        });

        it("Ne devrait pas permettre de voter deux fois", async function () {
            await electionSystem.connect(voter1).vote(0, 1);
            await expect(electionSystem.connect(voter1).vote(0, 1))
                .to.be.revertedWith("A deja vote");
        });

        it("Ne devrait pas permettre aux non-votants de voter", async function () {
            await expect(electionSystem.connect(nonVoter).vote(0, 1))
                .to.be.revertedWith("AccessControl:");
        });
    });

    describe("Fonctionnalités de pause", function () {
        it("Devrait permettre de mettre en pause et reprendre le contrat", async function () {
            await electionSystem.pause();
            expect(await electionSystem.paused()).to.be.true;
            
            await electionSystem.unpause();
            expect(await electionSystem.paused()).to.be.false;
        });

        it("Ne devrait pas permettre de voter pendant la pause", async function () {
            await electionSystem.addVoter(voter1.address);
            const startTime = await time.latest() + 100;
            const endTime = startTime + 3600;
            await electionSystem.createResolution("Test Resolution", startTime, endTime);
            await electionSystem.activateResolution(0);
            await time.increase(100);
            
            await electionSystem.pause();
            await expect(electionSystem.connect(voter1).vote(0, 1))
                .to.be.revertedWith("Pausable: paused");
        });
    });
});
