# ElectionSystem Smart Contract

## Description
ElectionSystem est un smart contract Solidity conçu pour gérer des élections et des votes de manière décentralisée sur la blockchain Ethereum. Il permet d'organiser des assemblées, de créer des résolutions, de gérer les votes et d'émettre des certificats NFT pour les participants.

## Fonctionnalités

### Principales fonctionnalités
- Organisation d'assemblées avec période de vote définie
- Création et gestion de résolutions
- Système de vote sécurisé (Pour, Contre, Abstention)
- Émission de certificats NFT pour les votants
- Gestion des rôles et permissions
- Système de pause d'urgence
- Historique des votes par utilisateur

### Sécurité
- Utilisation de OpenZeppelin pour les standards de sécurité
- Protection contre la réentrance
- Système de contrôle d'accès
- Mécanisme de pause

## Prérequis techniques
- Solidity ^0.8.24
- OpenZeppelin Contracts
- Environnement de développement Ethereum (Hardhat/Truffle)
- Node.js et npm

## Installation

```bash
npm install @openzeppelin/contracts
```

## Déploiement

Pour déployer le contrat, vous devez fournir les paramètres suivants :

```javascript
const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
const electionSystem = await ElectionSystem.deploy(
    "Nom du NFT",
    "SYMBOLE",
    minimumTokensRequired,
    "https://votre-api.com/certificats/"
);
```

## Utilisation principale

### Configuration d'une assemblée
```javascript
await electionSystem.configureAssembly(
    "Titre de l'assemblée",
    "Description de l'assemblée",
    startTimestamp,
    endTimestamp
);
```

### Création d'une résolution
```javascript
await electionSystem.createResolution(
    "Titre de la résolution",
    "Description de la résolution",
    startTime,
    endTime
);
```

### Vote
```javascript
await electionSystem.vote(resolutionId, voteChoice);
// voteChoice: 1 = POUR, 2 = CONTRE, 3 = ABSTENTION
```

## Rôles et Permissions

- `DEFAULT_ADMIN_ROLE`: Administrateur du système
- `VOTER_ROLE`: Rôle attribué aux votants autorisés

## Événements

- `ResolutionCreated`: Émis lors de la création d'une résolution
- `VoteCast`: Émis lorsqu'un vote est enregistré
- `VoteCertificateIssued`: Émis lors de l'émission d'un certificat NFT
- `AssemblyConfigured`: Émis lors de la configuration d'une assemblée

## Tests

```bash
npx hardhat test
```

## Sécurité et Audit

Avant tout déploiement en production :
- Effectuer un audit de sécurité complet
- Tester sur les réseaux de test (Goerli, Sepolia)
- Vérifier les permissions et les rôles

## License
GPL-3.0

## Contact
[Votre contact]

## Contribution
Les contributions sont les bienvenues. Veuillez suivre ces étapes :
1. Fork du projet
2. Création d'une branche pour votre fonctionnalité
3. Commit de vos changements
4. Push vers la branche
5. Ouverture d'une Pull Request

## Avertissement
Ce smart contract est fourni "tel quel" sans garantie. Utilisez-le à vos propres risques.
