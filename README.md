# Election System Smart Contract

Le système de vote électronique est une plateforme décentralisée permettant la création de résolutions, le vote, et l'émission de certificats pour les votants. Il utilise un contrôle d'accès basé sur les rôles, supporte la mise en pause d'urgence, et intègre des NFTs ERC721 pour les certificats de vote.

## Caractéristiques Principales

- **Contrôle d'Accès Basé sur les Rôles**:
  - `DEFAULT_ADMIN_ROLE`: Gestion des assemblées et résolutions
  - `VOTER_ROLE`: Participation aux votes

- **Système de Vote**:
  - Trois options de vote: `POUR`, `CONTRE`, et `ABSTENTION`
  - Suivi de la participation et vérification d'unicité des votes
  - Comptabilisation automatique des votes

- **Gestion des Résolutions**:
  - États possibles: `DRAFT`, `ACTIVE`, `CLOSED`, `NONE`
  - Création et mise à jour par les administrateurs
  - Période de vote configurable

- **Configuration d'Assemblée**:
  - Titre et description personnalisables
  - Période de vote définie
  - Validation des plages horaires

- **Certificats de Vote (NFTs)**:
  - Tokens ERC721 comme preuve de participation
  - URI de base configurable
  - Émission contrôlée par les administrateurs

## Déploiement

### Prérequis
```javascript
const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
const electionSystem = await ElectionSystem.deploy(
  "ElectionNFT",
  "ENFT",
  1,
  "https://example.com/certificates/"
);
```

### Paramètres de Déploiement
- `name`: Nom du token ERC721 (ex: "ElectionNFT")
- `symbol`: Symbole du token (ex: "ENFT")
- `minimumTokensRequired`: Nombre minimum de tokens requis
- `certificateBaseURI`: URI de base pour les certificats

## Guide d'Utilisation

### 1. Configuration Initiale
```javascript
// Attribution des rôles
await electionSystem.grantRole(VOTER_ROLE, voterAddress);

// Configuration de l'assemblée
await electionSystem.configureAssembly(
  "Assemblée Générale 2024",
  "Assemblée annuelle des actionnaires",
  startTime,
  endTime
);
```

### 2. Gestion des Résolutions
```javascript
// Création d'une résolution
await electionSystem.createResolution(
  "Résolution 1",
  "Description de la résolution",
  startTime,
  endTime
);

// Activation d'une résolution
await electionSystem.updateResolutionStatus(resolutionId, 1); // 1 = ACTIVE
```

### 3. Processus de Vote
```javascript
// Vote (1 = POUR, 2 = CONTRE, 3 = ABSTENTION)
await electionSystem.vote(resolutionId, 1);
```

## Tests

Le contrat inclut une suite de tests complète couvrant toutes les fonctionnalités principales.

### Installation et Exécution des Tests
```bash
npm install
npx hardhat test
```

### Couverture des Tests

1. **Initialisation et Configuration**
- Validation des paramètres de déploiement
- Configuration de l'assemblée
- Gestion des erreurs de configuration

2. **Gestion des Résolutions**
- Création de résolutions
- Mise à jour des statuts
- Validation des périodes

3. **Processus de Vote**
- Votes valides
- Prévention des votes multiples
- Comptabilisation des différents types de votes

4. **Certificats**
- Émission des certificats
- Contrôle d'accès pour l'émission

5. **Sécurité**
- Tests de contrôle d'accès
- Fonctionnalité de pause

## Sécurité

### Mécanismes de Protection
- Contrôle d'accès basé sur les rôles
- Protection contre la réentrance
- Système de pause d'urgence
- Validation des périodes temporelles

### Bonnes Pratiques
- Utilisation de `require` pour les validations critiques
- Erreurs personnalisées pour une meilleure gestion
- Événements pour le suivi des actions importantes

## Événements

- `ResolutionCreated(uint256 resolutionId, string title)`
- `VoteCast(uint256 resolutionId, address voter, VoteChoice choice)`
- `VoteCertificateIssued(address voter, uint256 tokenId)`
- `AssemblyConfigured(string title, uint256 startTime, uint256 endTime)`
- `ResolutionStatusUpdated(uint256 resolutionId, ResolutionStatus newStatus)`

## Licence

Ce projet est sous licence [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

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
