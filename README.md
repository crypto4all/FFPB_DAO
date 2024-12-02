# Système de Vote sur la Blockchain Ethereum

## Description
Ce projet implémente un système de vote décentralisé sur la blockchain Ethereum permettant de gérer des résolutions avec trois options de vote : POUR, CONTRE et ABSTENTION. Le système inclut une gestion des droits d'accès et une liste blanche des votants.

## Fonctionnalités

### Gestion des Droits
- Système de propriété (Owner)
- Liste blanche des votants
- Seul le propriétaire peut ajouter des résolutions
- Seules les adresses en liste blanche peuvent voter

### Résolutions
- Création de résolutions avec période de vote définie
- Trois options de vote : POUR, CONTRE, ABSTENTION
- États des résolutions : PENDING, ACTIVE, CLOSED
- Un votant ne peut voter qu'une seule fois par résolution

## Fonctions Principales

### Gestion de la Liste Blanche
```solidity
function addToWhitelist(address[] calldata _beneficiaries) public onlyOwner
function removeFromWhitelist(address _beneficiary) public onlyOwner
function isWhitelisted(address _beneficiary) public view returns (bool)
```

### Gestion des Résolutions
```solidity
function addResolution(string memory _description, uint256 _startTime, uint256 _endTime) public onlyOwner
function activateResolution(uint256 _resolutionId) public onlyOwner
function closeResolution(uint256 _resolutionId) public onlyOwner
```

### Vote
```solidity
function voteResolution(uint256 _resolutionId, Vote _choice) public onlyWhitelisted
```

### Consultation
```solidity
function getResolutionDetails(uint256 _resolutionId) public view returns (...)
function getVoterChoice(uint256 _resolutionId, address _voter) public view returns (Vote)
```

## Installation et Déploiement

1. Prérequis
   - Node.js
   - Truffle ou Hardhat
   - Un portefeuille Ethereum (ex: MetaMask)

2. Installation
```bash
npm install
```

3. Compilation
```bash
truffle compile
# ou
npx hardhat compile
```

4. Déploiement
```bash
truffle migrate --network <network_name>
# ou
npx hardhat run scripts/deploy.js --network <network_name>
```

## Utilisation

1. Déploiement du contrat
2. L'owner ajoute des adresses à la liste blanche
3. L'owner crée une résolution
4. L'owner active la résolution
5. Les votants whitelistés peuvent voter
6. L'owner clôture la résolution une fois la période de vote terminée

## Sécurité

- Vérifications des droits d'accès
- Protection contre les votes multiples
- Contrôles temporels sur les périodes de vote
- Validation des entrées

## Tests

```bash
truffle test
# ou
npx hardhat test
```

## Versions
- Solidity : ^0.8.24
- Node.js : v14+ recommandé

## Licence
GPL-3.0

## Auteur
[Votre Nom]

## Avertissement
Ce code est fourni à titre d'exemple et doit être audité avant toute utilisation en production.
