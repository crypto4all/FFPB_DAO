# Système de Vote NFT - Documentation

## Description
Système de vote décentralisé sur la blockchain Ethereum utilisant les NFTs comme preuve de participation. Le système permet de créer et gérer des résolutions, d'administrer les votes et de distribuer automatiquement des NFTs aux votants.

## Fonctionnalités Principales

### Administration
- Création et gestion de résolutions
- Ajout/suppression de votants (individuel ou en masse)
- Activation/clôture des votes
- Système de pause d'urgence

### Votants
- Vote sur les résolutions (Pour, Contre, Abstention)
- Réception automatique de NFT après le vote
- Vérification du statut de votant

### Sécurité
- Gestion des rôles avec AccessControl
- Protection contre la réentrance
- Système de pause
- Utilisation de SafeMath pour les calculs

## Prérequis Techniques

```bash
Node.js >= 16.0.0
npm >= 8.0.0
Solidity ^0.8.24
```

## Installation

```bash
# Cloner le repository
git clone [URL_DU_REPO]

# Installer les dépendances
npm install

# Installer les contrats OpenZeppelin
npm install @openzeppelin/contracts
```

## Déploiement

```javascript
const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
const election = await ElectionSystem.deploy(
    "VoteNFT",
    "VOTE",
    "https://api.vote-nft.com/metadata/"
);
await election.deployed();
```

## Guide d'Utilisation

### Administration

```javascript
// Ajouter un votant unique
await election.addVoter("0x123...");

// Ajouter plusieurs votants
const voters = ["0x123...", "0x456...", "0x789..."];
await election.addVoters(voters);

// Créer une résolution
await election.createResolution(
    "Description de la résolution",
    startTimestamp,
    endTimestamp
);

// Activer une résolution
await election.activateResolution(resolutionId);

// Clôturer une résolution
await election.closeResolution(resolutionId);
```

### Votants

```javascript
// Voter sur une résolution
await election.vote(resolutionId, 1); // 1=POUR, 2=CONTRE, 3=ABSTENTION

// Vérifier son statut de votant
const isVoter = await election.isVoter(address);
```

## Structure des Données

### Énumérations

```solidity
enum Status { DRAFT, ACTIVE, CLOSED }
enum Vote { NONE, POUR, CONTRE, ABSTENTION }
```

### Structure de Résolution

```solidity
struct Resolution {
    string description;
    uint256 startTime;
    uint256 endTime;
    Status status;
    uint256 votePour;
    uint256 voteContre;
    uint256 voteAbstention;
    mapping(address => Vote) voterChoices;
}
```

## Événements

```solidity
event ResolutionCreated(uint256 indexed resolutionId, string description);
event ResolutionStatusChanged(uint256 indexed resolutionId, Status newStatus);
event VoteRegistered(uint256 indexed resolutionId, address indexed voter, Vote choice);
event VoterAdded(address indexed account);
event VoterRemoved(address indexed account);
```

## Sécurité

### Rôles
- `DEFAULT_ADMIN_ROLE` : Administrateur système
- `VOTER_ROLE` : Votants autorisés

### Protections
- Vérifications des timestamps
- Protection contre les votes multiples
- Limitation du nombre de votants par transaction (max 100)
- Vérification des adresses nulles

## Tests

```bash
# Exécuter les tests
npx hardhat test
```

## Licence
GPL-3.0

## Support
Pour toute question ou support, veuillez ouvrir une issue dans le repository GitHub.

## Contribution
Les contributions sont les bienvenues ! Veuillez consulter notre guide de contribution avant de soumettre une PR.
