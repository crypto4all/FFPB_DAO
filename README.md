# ElectionSystem Smart Contract

## Description
**ElectionSystem** est un smart contract Solidity conçu pour gérer des élections et des votes de manière décentralisée sur la blockchain Ethereum. Ce système offre une solution complète pour organiser des assemblées, créer des résolutions, gérer les votes des participants et émettre des certificats NFT pour les votants.

## Fonctionnalités

### Principales fonctionnalités
- **Organisation d'assemblées** : Configuration d'assemblées avec des périodes de vote définies.
- **Création et gestion de résolutions** : Ajout de résolutions à voter dans une assemblée.
- **Système de vote sécurisé** : Les participants peuvent voter "Pour", "Contre" ou "Abstention".
- **Émission de certificats NFT** : Attribution de certificats numériques aux participants ayant voté.
- **Gestion des rôles et permissions** : Contrôle d'accès basé sur les rôles (`DEFAULT_ADMIN_ROLE`, `VOTER_ROLE`).
- **Système de pause d'urgence** : Possibilité de mettre en pause le contrat pour des raisons de sécurité.
- **Historique des votes** : Suivi des votes effectués par chaque utilisateur.

### Sécurité
- **Standards OpenZeppelin** : Utilisation des bibliothèques éprouvées pour les rôles, les ERC-721, et les mécanismes de sécurité.
- **Protection contre la réentrance** : Sécurisation des appels externes pour éviter les attaques.
- **Système de contrôle d'accès** : Gestion des permissions avec des rôles précis.
- **Mécanisme de pause** : Suspension des fonctionnalités critiques en cas d'urgence.

## Prérequis techniques
- **Solidity** : Version ^0.8.24
- **OpenZeppelin Contracts** : Pour les standards ERC-721, AccessControl, et Pausable.
- **Environnement Ethereum** : Hardhat recommandé pour le développement et le test.
- **Node.js** et **npm** : Pour installer les dépendances et exécuter les scripts.

## Installation

Clonez le projet et installez les dépendances nécessaires :

```bash
git clone https://github.com/crypto4all/FFPB_DAO.git
cd FFPB_DAO
npm install
```

Installez également les contrats OpenZeppelin :

```bash
npm install @openzeppelin/contracts
```

## Déploiement

Pour déployer le contrat, utilisez le script suivant dans votre environnement Hardhat :

```javascript
const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
const electionSystem = await ElectionSystem.deploy(
    "Nom du NFT", // Nom du certificat NFT
    "SYMBOLE",    // Symbole du NFT
    minimumTokensRequired, // Nombre minimal de tokens requis pour voter
    "https://votre-api.com/certificats/" // URI de base pour les certificats NFT
);
await electionSystem.deployed();
console.log("ElectionSystem déployé à l'adresse :", electionSystem.address);
```

## Utilisation principale

### 1. Configuration d'une assemblée
Configurez une assemblée avec un titre, une description et une période de vote :

```javascript
await electionSystem.configureAssembly(
    "Titre de l'assemblée",
    "Description de l'assemblée",
    startTimestamp, // Timestamp de début
    endTimestamp    // Timestamp de fin
);
```

### 2. Création d'une résolution
Ajoutez une résolution à l'assemblée en cours :

```javascript
await electionSystem.createResolution(
    "Titre de la résolution",
    "Description de la résolution",
    startTime, // Timestamp de début du vote pour cette résolution
    endTime    // Timestamp de fin du vote pour cette résolution
);
```

### 3. Vote
Les votants autorisés peuvent voter pour une résolution :

```javascript
await electionSystem.vote(resolutionId, voteChoice);
// voteChoice : 1 = POUR, 2 = CONTRE, 3 = ABSTENTION
```

### 4. Émission de certificats NFT
Une fois le vote terminé, les certificats NFT sont automatiquement émis pour les votants.

## Rôles et Permissions

- **`DEFAULT_ADMIN_ROLE`** : Administrateur du système, capable de configurer des assemblées, de créer des résolutions et de gérer les rôles.
- **`VOTER_ROLE`** : Rôle attribué aux participants autorisés à voter.

## Événements

- **`AssemblyConfigured`** : Émis lorsqu'une assemblée est configurée.
- **`ResolutionCreated`** : Émis lorsqu'une résolution est créée.
- **`VoteCast`** : Émis lorsqu'un vote est enregistré.
- **`VoteCertificateIssued`** : Émis lorsqu'un certificat NFT est émis pour un votant.

## Tests

Exécutez les tests pour valider les fonctionnalités du contrat :

```bash
npx hardhat test
```

Les tests incluent :
- Vérification des rôles et permissions.
- Création et gestion des assemblées.
- Processus de vote.
- Émission de certificats NFT.
- Scénarios de pause et reprise.

## Sécurité et Audit

Avant de déployer en production, assurez-vous de :
- Effectuer un audit de sécurité complet avec une tierce partie.
- Tester sur des réseaux de test publics (Goerli, Sepolia).
- Vérifier les permissions et les rôles pour éviter tout accès non autorisé.

## License
Ce projet est sous licence **GPL-3.0**. Consultez le fichier LICENSE pour plus de détails.

## Support et Contact
Pour toute question ou assistance :
- **GitHub Issues** : [https://github.com/crypto4all/FFPB_DAO/issues](https://github.com/crypto4all/FFPB_DAO/issues)
- **Email** : [christophe.ozcan@crypto4all.com](mailto:christophe.ozcan@crypto4all.com)

## Contribution

Les contributions sont les bienvenues ! Voici comment procéder :
1. Forkez le projet.
2. Créez une branche pour votre fonctionnalité (`feature/ma-fonctionnalité`).
3. Committez vos changements.
4. Poussez la branche sur votre fork.
5. Ouvrez une Pull Request sur le dépôt principal.

## Avertissement

Ce smart contract est fourni "tel quel" sans aucune garantie. L'utilisation de ce contrat est entièrement à vos risques et périls. Assurez-vous de bien comprendre son fonctionnement avant de l'utiliser en production.
