const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ElectionSystem", function () {
    let ElectionSystem;
    let electionSystem;
    let owner, voter1, voter2, addr3;

    // Configuration des constantes
    const NAME = "Election Certificate";
    const SYMBOL = "ELECT";
    const MIN_TOKENS = 1;
    const BASE_URI = "https://api.election-system.com/certificates/";
    const VOTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("VOTER_ROLE"));

    beforeEach(async function () {
        // Récupération des comptes de test
        [owner, voter1, voter2, addr3] = await ethers.getSigners();

        // Déploiement du contrat
        const ElectionSystemFactory = await ethers.getContractFactory("ElectionSystem");
        electionSystem = await ElectionSystemFactory.deploy(NAME, SYMBOL, MIN_TOKENS, BASE_URI);
        await electionSystem.waitForDeployment();

        // Attribution des rôles de votants
        await electionSystem.grantRole(VOTER_ROLE, voter1.address);
        await electionSystem.grantRole(VOTER_ROLE, voter2.address);
    });

    describe("Déploiement", function () {
        it("Devrait définir le bon propriétaire", async function () {
            expect(await electionSystem.hasRole(await electionSystem.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
        });

        it("Devrait initialiser avec les bons paramètres", async function () {
            expect(await electionSystem.name()).to.equal(NAME);
            expect(await electionSystem.symbol()).to.equal(SYMBOL);
            expect(await electionSystem.minimumTokensRequired()).to.equal(MIN_TOKENS);
            expect(await electionSystem.getCertificateBaseURI()).to.equal(BASE_URI);
        });
    });

    describe("Configuration de l'assemblée", function () {
        const assemblyTitle = "Assemblée Générale 2024";
        const assemblyDescription = "Description de l'assemblée";
        let startTime, endTime;

        beforeEach(async function () {
            startTime = (await time.latest()) + 3600; // Début dans 1 heure
            endTime = startTime + 7200; // Durée de 2 heures
        });

        it("Devrait permettre à l'admin de configurer une assemblée", async function () {
            await expect(electionSystem.configureAssembly(
                assemblyTitle,
                assemblyDescription,
                startTime,
                endTime
            )).to.emit(electionSystem, "AssemblyConfigured")
              .withArgs(assemblyTitle, startTime, endTime);

            const configuredAssembly = await electionSystem.assemblyTitle();
            expect(configuredAssembly).to.equal(assemblyTitle);
        });

        it("Ne devrait pas permettre une configuration par un non-admin", async function () {
            await expect(electionSystem.connect(voter1).configureAssembly(
                assemblyTitle,
                assemblyDescription,
                startTime,
                endTime
            )).to.be.revertedWith(/AccessControl: account .* is missing role .*/);
        });
    });

    describe("Gestion des résolutions", function () {
        const resolutionTitle = "Résolution #1";
        const resolutionDescription = "Description de la résolution";
        let assemblyStart, assemblyEnd, resolutionStart, resolutionEnd;

        beforeEach(async function () {
            assemblyStart = (await time.latest()) + 3600;
            assemblyEnd = assemblyStart + 86400;
            resolutionStart = assemblyStart + 3600;
            resolutionEnd = assemblyEnd - 3600;

            await electionSystem.configureAssembly(
                "Assemblée Test",
                "Description Test",
                assemblyStart,
                assemblyEnd
            );
        });

        it("Devrait créer une nouvelle résolution", async function () {
            await expect(electionSystem.createResolution(
                resolutionTitle,
                resolutionDescription,
                resolutionStart,
                resolutionEnd
            )).to.emit(electionSystem, "ResolutionCreated")
              .withArgs(0, resolutionTitle);

            const resolution = await electionSystem.getResolutionDetails(0);
            expect(resolution.title).to.equal(resolutionTitle);
        });
    });

    describe("Processus de vote", function () {
        let resolutionId;
        let assemblyStart, assemblyEnd, resolutionStart, resolutionEnd;

        beforeEach(async function () {
            assemblyStart = (await time.latest()) + 3600;
            assemblyEnd = assemblyStart + 86400;
            resolutionStart = assemblyStart + 3600;
            resolutionEnd = assemblyEnd - 3600;

            await electionSystem.configureAssembly(
                "Assemblée Test",
                "Description Test",
                assemblyStart,
                assemblyEnd
            );

            await electionSystem.createResolution(
                "Résolution Test",
                "Description Test",
                resolutionStart,
                resolutionEnd
            );
            resolutionId = 0;
        });

        it("Devrait permettre aux votants autorisés de voter", async function () {
            await time.increaseTo(resolutionStart);

            await expect(electionSystem.connect(voter1).vote(resolutionId, 1))
                .to.emit(electionSystem, "VoteCast")
                .withArgs(resolutionId, voter1.address, 1);
        });

        it("Ne devrait pas permettre de voter deux fois", async function () {
            await time.increaseTo(resolutionStart);

            await electionSystem.connect(voter1).vote(resolutionId, 1);
            await expect(electionSystem.connect(voter1).vote(resolutionId, 2))
                .to.be.revertedWith("Already voted");
        });
    });

    describe("Gestion des certificats NFT", function () {
        it("Devrait émettre un certificat après tous les votes", async function () {
            // Configuration et test à implémenter
        });

        it("Devrait permettre la mise à jour de l'URI de base", async function () {
            const newBaseURI = "https://new-api.election-system.com/certificates/";
            await electionSystem.setCertificateBaseURI(newBaseURI);
            expect(await electionSystem.getCertificateBaseURI()).to.equal(newBaseURI);
        });
    });

    describe("Fonctions de pause", function () {
        it("Devrait permettre à l'admin de mettre en pause", async function () {
            await electionSystem.pause();
            expect(await electionSystem.paused()).to.be.true;
        });

        it("Devrait permettre à l'admin de reprendre", async function () {
            await electionSystem.pause();
            await electionSystem.unpause();
            expect(await electionSystem.paused()).to.be.false;
        });

        it("Ne devrait pas permettre de voter pendant la pause", async function () {
            await electionSystem.pause();
            await expect(electionSystem.connect(voter1).vote(0, 1))
                .to.be.revertedWith("Pausable: paused");
        });
    });
});
