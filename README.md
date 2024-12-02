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
const isVoter = await election.hasRole(VOTER_ROLE, address);
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

## Tests

### Installation des dépendances de test

```bash
npm install --save-dev @nomicfoundation/hardhat-network-helpers chai
```

### Structure des tests

```javascript
describe("ElectionSystem", function () {
    // Tests d'initialisation
    describe("Initialisation", function () {
        // Vérifie le nom, symbole et rôles
    });

    // Tests de gestion des votants
    describe("Gestion des votants", function () {
        // Ajout/suppression de votants
        // Gestion des permissions
    });

    // Tests des résolutions
    describe("Gestion des résolutions", function () {
        // Création et activation
        // Validation des timestamps
    });

    // Tests du processus de vote
    describe("Processus de vote", function () {
        // Vote et vérification
        // Contraintes temporelles
        // Distribution NFT
    });

    // Tests des mécanismes de sécurité
    describe("Fonctions de pause", function () {
        // Pause/Unpause
        // Restrictions pendant la pause
    });
});
```

### Exécution des tests

```bash
# Exécuter tous les tests
npx hardhat test

# Exécuter un fichier de test spécifique
npx hardhat test test/ElectionSystem.test.js

# Exécuter avec couverture de code
npx hardhat coverage
```

### Cas de Tests Couverts

1. **Initialisation**
   - Déploiement correct du contrat
   - Configuration des paramètres initiaux
   - Attribution des rôles administrateurs

2. **Gestion des Votants**
   - Ajout d'un votant unique
   - Ajout de plusieurs votants en masse
   - Suppression de votants
   - Vérification des permissions
   - Comptage des votants

3. **Gestion des Résolutions**
   - Création de résolution
   - Validation des timestamps
   - Activation/désactivation
   - Contraintes temporelles

4. **Processus de Vote**
   - Vote valide
   - Prévention des votes multiples
   - Respect des périodes de vote
   - Distribution automatique des NFTs
   - Comptabilisation des votes

5. **Sécurité**
   - Mécanisme de pause
   - Contrôle des accès
   - Gestion des erreurs
   - Protection contre les votes non autorisés

## Sécurité et Bonnes Pratiques

### Gestion des Accès
- Utilisation du pattern AccessControl d'OpenZeppelin
- Séparation claire des rôles (admin, votant)
- Vérifications systématiques des permissions

### Protection contre les Attaques
- ReentrancyGuard pour les fonctions critiques
- Validation des entrées utilisateur
- Gestion sécurisée des timestamps

### Gestion des Erreurs
- Messages d'erreur explicites
- Vérifications des conditions préalables
- Gestion des cas limites

## Maintenance et Mises à Jour

### Mises à Jour
- Système de pause pour maintenance
- Possibilité de mise à jour des rôles
- Flexibilité dans la gestion des résolutions

### Surveillance
- Événements pour toutes les actions importantes
- Traçabilité des votes et des modifications
- Métriques de participation

## Support et Contact

Pour toute question ou support :
- GitHub Issues : https://github.com/crypto4all/FFPB_DAO/tree/main/issues
- Email : christophe.ozcan@crypto4all.com

## Licence

Ce projet est sous licence GPL-3.0. Voir le fichier LICENSE pour plus de détails.
