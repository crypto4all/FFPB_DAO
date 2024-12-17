const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ElectionSystem", function () {
  let electionSystem;
  let admin, voter1, voter2, voter3, nonVoter;
  let currentTime, assemblyStart, assemblyEnd;
  const VOTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("VOTER_ROLE"));

  before(async function () {
    [admin, voter1, voter2, voter3, nonVoter] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // Déploiement du contrat
    const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
    electionSystem = await ElectionSystem.deploy(
      "ElectionNFT",
      "ENFT",
      1,
      "https://example.com/certificates/"
    );
    await electionSystem.deployed();

    // Configuration des temps
    currentTime = await time.latest();
    assemblyStart = currentTime + 3600; // Début dans 1 heure
    assemblyEnd = assemblyStart + 86400; // Fin 24 heures après le début

    // Attribution des rôles
    await electionSystem.grantRole(VOTER_ROLE, voter1.address);
    await electionSystem.grantRole(VOTER_ROLE, voter2.address);
    await electionSystem.grantRole(VOTER_ROLE, voter3.address);
  });

  describe("Initialisation et Configuration", function () {
    it("Devrait initialiser correctement le contrat avec les bonnes valeurs", async function () {
      expect(await electionSystem.name()).to.equal("ElectionNFT");
      expect(await electionSystem.symbol()).to.equal("ENFT");
      expect(await electionSystem.minimumTokensRequired()).to.equal(1);
      expect(await electionSystem.hasRole(await electionSystem.DEFAULT_ADMIN_ROLE(), admin.address)).to.be.true;
    });

    it("Devrait configurer correctement une assemblée", async function () {
      await electionSystem.configureAssembly(
        "Assemblée Générale 2024",
        "Assemblée annuelle des actionnaires",
        assemblyStart,
        assemblyEnd
      );

      expect(await electionSystem.assemblyTitle()).to.equal("Assemblée Générale 2024");
      expect(await electionSystem.assemblyDescription()).to.equal("Assemblée annuelle des actionnaires");
      expect(await electionSystem.assemblyStartTime()).to.equal(assemblyStart);
      expect(await electionSystem.assemblyEndTime()).to.equal(assemblyEnd);
    });

    it("Ne devrait pas permettre une configuration invalide de l'assemblée", async function () {
      await expect(
        electionSystem.configureAssembly(
          "",
          "Description",
          assemblyStart,
          assemblyEnd
        )
      ).to.be.revertedWithCustomError(electionSystem, "EmptyString");

      await expect(
        electionSystem.configureAssembly(
          "Titre",
          "Description",
          currentTime - 3600,
          assemblyEnd
        )
      ).to.be.revertedWithCustomError(electionSystem, "InvalidTimeRange");
    });
  });

  describe("Gestion des Résolutions", function () {
    beforeEach(async function () {
      await electionSystem.configureAssembly(
        "Assemblée Test",
        "Description Test",
        assemblyStart,
        assemblyEnd
      );
    });

    it("Devrait créer une résolution avec succès", async function () {
      const tx = await electionSystem.createResolution(
        "Résolution 1",
        "Description de la résolution",
        assemblyStart,
        assemblyEnd
      );

      const receipt = await tx.wait();
      const event = receipt.events?.find(e => e.event === "ResolutionCreated");
      expect(event).to.not.be.undefined;
      expect(event.args.title).to.equal("Résolution 1");

      const resolution = await electionSystem.getResolutionDetails(0);
      expect(resolution.title).to.equal("Résolution 1");
      expect(resolution.status).to.equal(0); // DRAFT
    });

    it("Devrait mettre à jour le statut d'une résolution", async function () {
      await electionSystem.createResolution(
        "Résolution 1",
        "Description",
        assemblyStart,
        assemblyEnd
      );

      await electionSystem.updateResolutionStatus(0, 1); // Passage à ACTIVE
      const resolution = await electionSystem.getResolutionDetails(0);
      expect(resolution.status).to.equal(1); // ACTIVE
    });
  });

  describe("Processus de Vote", function () {
    beforeEach(async function () {
      await electionSystem.configureAssembly(
        "Assemblée Test",
        "Description Test",
        assemblyStart,
        assemblyEnd
      );

      await electionSystem.createResolution(
        "Résolution 1",
        "Description",
        assemblyStart,
        assemblyEnd
      );

      await electionSystem.updateResolutionStatus(0, 1); // ACTIVE
      await time.increaseTo(assemblyStart + 1);
    });

    it("Devrait permettre un vote valide", async function () {
      await expect(electionSystem.connect(voter1).vote(0, 1)) // POUR
        .to.emit(electionSystem, "VoteCast")
        .withArgs(0, voter1.address, 1);

      const resolution = await electionSystem.getResolutionDetails(0);
      expect(resolution.votesPour).to.equal(1);
    });

    it("Ne devrait pas permettre de voter deux fois", async function () {
      await electionSystem.connect(voter1).vote(0, 1);
      await expect(
        electionSystem.connect(voter1).vote(0, 1)
      ).to.be.revertedWith("Already voted");
    });

    it("Devrait comptabiliser correctement différents types de votes", async function () {
      await electionSystem.connect(voter1).vote(0, 1); // POUR
      await electionSystem.connect(voter2).vote(0, 2); // CONTRE
      await electionSystem.connect(voter3).vote(0, 3); // ABSTENTION

      const resolution = await electionSystem.getResolutionDetails(0);
      expect(resolution.votesPour).to.equal(1);
      expect(resolution.votesContre).to.equal(1);
      expect(resolution.votesAbstention).to.equal(1);
    });
  });

  describe("Gestion des Certificats", function () {
    it("Devrait émettre un certificat de vote", async function () {
      await expect(electionSystem.issueVoteCertificate(voter1.address))
        .to.emit(electionSystem, "VoteCertificateIssued");

      expect(await electionSystem.balanceOf(voter1.address)).to.equal(1);
    });

    it("Ne devrait pas permettre à un non-admin d'émettre un certificat", async function () {
      await expect(
        electionSystem.connect(nonVoter).issueVoteCertificate(voter1.address)
      ).to.be.reverted;
    });
  });

  describe("Sécurité et Contrôle d'Accès", function () {
    it("Devrait respecter les contrôles d'accès", async function () {
      await expect(
        electionSystem.connect(nonVoter).vote(0, 1)
      ).to.be.reverted;

      await expect(
        electionSystem.connect(voter1).configureAssembly(
          "Test",
          "Description",
          assemblyStart,
          assemblyEnd
        )
      ).to.be.reverted;
    });

    it("Devrait gérer correctement la pause", async function () {
      await electionSystem.pause();
      await expect(
        electionSystem.connect(voter1).vote(0, 1)
      ).to.be.revertedWith("Pausable: paused");

      await electionSystem.unpause();
      // Le vote devrait maintenant être possible (si les autres conditions sont remplies)
    });
  });
});
