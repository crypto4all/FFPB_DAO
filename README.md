Voici le README.md mis à jour avec les nouvelles fonctionnalités :

```markdown
# Système de Vote NFT - Documentation

## Description
Système de vote décentralisé sur la blockchain Ethereum utilisant les NFTs comme preuve de participation. Le système permet de créer et gérer des résolutions, d'administrer les votes et de distribuer automatiquement des NFTs aux votants.

## Fonctionnalités Principales

### Administration
- Création et gestion de résolutions
- Ajout/suppression de votants (individuel ou en masse)
- Activation/clôture des votes
- Système de pause d'urgence
- Gestion des périodes de vote avec timestamps

### Votants
- Vote sur les résolutions (Pour, Contre, Abstention)
- Réception automatique de NFT après le vote
- Vérification du statut de votant
- Participation unique par résolution

### Sécurité
- Gestion des rôles avec AccessControl
- Protection contre la réentrance
- Système de pause
- Vérifications temporelles strictes

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

// Mettre en pause le système
await election.pause();

// Reprendre le système
await election.unpause();
```

### Votants

```javascript
// Voter sur une résolution
await election.vote(resolutionId, VoteChoice.FOR); // FOR, AGAINST, ABSTAIN

// Consulter les détails d'une résolution
const details = await election.getResolutionDetails(resolutionId);

// Vérifier son NFT
const balance = await election.balanceOf(voterAddress);
```

## Structure des Données

### Énumérations

```solidity
enum Status { DRAFT, ACTIVE, CLOSED }
enum VoteChoice { NONE, FOR, AGAINST, ABSTAIN }
```

### Structure de Résolution

```solidity
struct Resolution {
    string description;
    uint256 startTime;
    uint256 endTime;
    Status status;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 votesAbstain;
    mapping(address => bool) hasVoted;
}
```

## Tests

### Installation des dépendances de test

```bash
npm install --save-dev @nomicfoundation/hardhat-network-helpers chai
```

### Exécution des tests

```bash
# Exécuter tous les tests
npx hardhat test

# Exécuter avec couverture de code
npx hardhat coverage
```

### Cas de Tests Couverts

1. **Initialisation**
   - Déploiement du contrat
   - Configuration des paramètres initiaux
   - Attribution des rôles

2. **Gestion des Votants**
   - Ajout/suppression de votants
   - Gestion des permissions
   - Comptage des votants

3. **Gestion des Résolutions**
   - Création et cycle de vie des résolutions
   - Validation des périodes de vote
   - Activation et clôture

4. **Processus de Vote**
   - Vote et vérification
   - Distribution des NFTs
   - Contraintes temporelles

5. **Sécurité**
   - Mécanisme de pause
   - Protection contre la réentrance
   - Gestion des accès

## Sécurité et Bonnes Pratiques

- Utilisation d'OpenZeppelin pour les standards de sécurité
- Vérifications systématiques des permissions et conditions
- Protection contre les attaques courantes
- Système de pause d'urgence
- Émission d'événements pour la traçabilité

## Maintenance et Mises à Jour

- Système modulaire permettant les évolutions
- Documentation complète du code
- Tests exhaustifs pour la maintenance

## Contribution

Les contributions sont les bienvenues. Veuillez suivre le processus standard de fork et pull request.
```

Les principales mises à jour incluent :
- Ajout des nouvelles fonctionnalités de sécurité
- Mise à jour des structures de données
- Amélioration de la documentation des tests
- Clarification des processus de vote et de gestion des NFTs
- Ajout des informations sur le système de pause

## Support et Contact

Pour toute question ou support :
- GitHub Issues : https://github.com/crypto4all/FFPB_DAO/tree/main/issues
- Email : christophe.ozcan@crypto4all.com

## Licence

Ce projet est sous licence GPL-3.0. Voir le fichier LICENSE pour plus de détails.
