# Système de Vote avec NFT - Documentation

## Description
Ce système de vote sur la blockchain Ethereum permet de gérer des résolutions avec distribution automatique de NFTs aux votants. Le système inclut une whitelist, un mécanisme de pause et une gestion complète du cycle de vie des votes.

## Fonctionnalités Principales

### 1. Gestion des Résolutions
- Création de nouvelles résolutions
- Activation/désactivation des résolutions
- Vote (Pour, Contre, Abstention)
- Clôture automatique des votes

### 2. Système de NFT
- Distribution automatique de NFTs aux votants
- Mécanisme de pause en cas de problème
- Traçabilité des distributions

### 3. Sécurité
- Système de whitelist
- Contrôles d'accès (Ownable)
- Gestion des erreurs

## Installation

```bash
npm install @openzeppelin/contracts
```

## Déploiement

```solidity
Election election = new Election(
    "VoteNFT",      // Nom du NFT
    "VOTE",         // Symbole du NFT
    "https://api.vote-nft.com/metadata/"  // URI de base
);
```

## Utilisation

### 1. Configuration Initiale
```solidity
// Ajouter une adresse à la whitelist
election.addToWhitelist(address);

// Créer une résolution
election.createResolution(
    "Description de la résolution",
    startTimestamp,
    endTimestamp
);
```

### 2. Gestion des Votes
```solidity
// Activer une résolution
election.activateResolution(resolutionId);

// Voter
election.vote(resolutionId, Vote.POUR);  // ou CONTRE, ABSTENTION

// Clôturer une résolution
election.closeResolution(resolutionId);
```

### 3. Gestion des NFTs
```solidity
// Mettre en pause la distribution
election.voteNFT.pause();

// Reprendre la distribution
election.voteNFT.unpause();

// Vérifier si un votant a reçu son NFT
bool hasNFT = election.hasReceivedNFT(resolutionId, voterAddress);
```

## Structure des Événements

```solidity
event ResolutionCreated(uint256 indexed resolutionId, string description);
event ResolutionStatusChanged(uint256 indexed resolutionId, Status newStatus);
event VoteRegistered(uint256 indexed resolutionId, address indexed voter, Vote choice);
event NFTMinted(address indexed voter, uint256 indexed resolutionId, uint256 tokenId);
event NFTMintFailed(address indexed voter, uint256 indexed resolutionId);
```

## États et Énumérations

### Status des Résolutions
```solidity
enum Status { DRAFT, ACTIVE, CLOSED }
```

### Options de Vote
```solidity
enum Vote { NONE, POUR, CONTRE, ABSTENTION }
```

## Sécurité

### Précautions
- Vérification des timestamps
- Contrôle des accès
- Gestion des erreurs de mint
- Protection contre les votes multiples

### Bonnes Pratiques
- Tester sur un réseau de test avant le déploiement
- Auditer le code avant utilisation en production
- Maintenir une whitelist à jour
- Surveiller les événements de mint échoués

## Tests Recommandés

```javascript
// Exemple de tests à implémenter
describe("Election Contract", () => {
    it("Should create a resolution")
    it("Should activate a resolution")
    it("Should allow whitelisted addresses to vote")
    it("Should distribute NFTs correctly")
    it("Should handle pause mechanism")
});
```

## Maintenance

### Mises à Jour Recommandées
- Vérification régulière des distributions de NFTs
- Surveillance des événements d'échec
- Mise à jour de la whitelist

## Support

Pour toute question ou assistance :
- Créer une issue sur GitHub
- Contacter l'équipe de développement

## Licence
GPL-3.0

---

**Note** : Ce document est une référence technique. Pour une utilisation en production, assurez-vous de :
1. Effectuer un audit de sécurité complet
2. Tester exhaustivement sur les réseaux de test
3. Vérifier la conformité réglementaire dans votre juridiction
