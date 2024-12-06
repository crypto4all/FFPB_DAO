// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ElectionSystem is AccessControl, ReentrancyGuard, ERC721, Pausable {
    // Définition des rôles
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    // Énumérations
    enum Status { DRAFT, ACTIVE, CLOSED }
    enum VoteChoice { NONE, FOR, AGAINST, ABSTAIN }

    // Structure de résolution
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

    // Variables d'état
    uint256 private _votersCount;
    uint256 private _resolutionCounter;
    uint256 private _tokenIdCounter;
    string private _baseTokenURI;
    mapping(uint256 => Resolution) public resolutions;

    // Événements
    event VoterAdded(address indexed voter);
    event VoterRemoved(address indexed voter);
    event ResolutionCreated(uint256 indexed resolutionId, string description);
    event ResolutionActivated(uint256 indexed resolutionId);
    event ResolutionClosed(uint256 indexed resolutionId);
    event Voted(uint256 indexed resolutionId, address indexed voter, VoteChoice choice);
    event NFTMinted(address indexed voter, uint256 tokenId);

    // Constructeur
    constructor(string memory name, string memory symbol, string memory baseURI) 
        ERC721(name, symbol) 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseURI;
    }

    // Modificateurs
    modifier resolutionExists(uint256 resolutionId) {
        require(resolutionId < _resolutionCounter, "Resolution inexistante");
        _;
    }

    modifier onlyDuringVotingPeriod(uint256 resolutionId) {
        require(
            resolutions[resolutionId].status == Status.ACTIVE &&
            block.timestamp >= resolutions[resolutionId].startTime &&
            block.timestamp <= resolutions[resolutionId].endTime,
            "Periode de vote invalide"
        );
        _;
    }

    // Fonctions de gestion des votants
    function addVoter(address _voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_voter != address(0), "Adresse nulle non autorisee");
        require(!hasRole(VOTER_ROLE, _voter), "Deja un votant");
        
        _grantRole(VOTER_ROLE, _voter);
        _votersCount++;
        
        emit VoterAdded(_voter);
    }

    function addVoters(address[] calldata _voters) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint i = 0; i < _voters.length; i++) {
            addVoter(_voters[i]);
        }
    }

    function removeVoter(address _voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(VOTER_ROLE, _voter), "Pas un votant");
        
        revokeRole(VOTER_ROLE, _voter);
        _votersCount--;
        
        emit VoterRemoved(_voter);
    }

    // Fonctions de gestion des résolutions
    function createResolution(
        string memory description,
        uint256 startTime,
        uint256 endTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startTime > block.timestamp, "Date de debut invalide");
        require(endTime > startTime, "Date de fin invalide");

        uint256 resolutionId = _resolutionCounter++;
        Resolution storage newResolution = resolutions[resolutionId];
        
        newResolution.description = description;
        newResolution.startTime = startTime;
        newResolution.endTime = endTime;
        newResolution.status = Status.DRAFT;

        emit ResolutionCreated(resolutionId, description);
    }

    function activateResolution(uint256 resolutionId) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        resolutionExists(resolutionId) 
    {
        require(resolutions[resolutionId].status == Status.DRAFT, "Statut invalide");
        resolutions[resolutionId].status = Status.ACTIVE;
        emit ResolutionActivated(resolutionId);
    }

    function closeResolution(uint256 resolutionId) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        resolutionExists(resolutionId) 
    {
        require(resolutions[resolutionId].status == Status.ACTIVE, "Statut invalide");
        resolutions[resolutionId].status = Status.CLOSED;
        emit ResolutionClosed(resolutionId);
    }

    // Fonction de vote
    function vote(uint256 resolutionId, VoteChoice choice) 
        external 
        whenNotPaused
        nonReentrant
        onlyRole(VOTER_ROLE)
        resolutionExists(resolutionId)
        onlyDuringVotingPeriod(resolutionId)
    {
        require(!resolutions[resolutionId].hasVoted[msg.sender], "A deja vote");
        require(choice != VoteChoice.NONE, "Vote invalide");

        Resolution storage resolution = resolutions[resolutionId];
        resolution.hasVoted[msg.sender] = true;

        if (choice == VoteChoice.FOR) {
            resolution.votesFor++;
        } else if (choice == VoteChoice.AGAINST) {
            resolution.votesAgainst++;
        } else {
            resolution.votesAbstain++;
        }

        // Mint NFT pour le votant
        _mintVoteNFT(msg.sender);
        
        emit Voted(resolutionId, msg.sender, choice);
    }

    // Fonctions NFT
    function _mintVoteNFT(address voter) internal {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(voter, tokenId);
        emit NFTMinted(voter, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Fonctions de pause
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Fonctions de consultation
    function getVotersCount() public view returns (uint256) {
        return _votersCount;
    }

    function getResolutionDetails(uint256 resolutionId) 
        external 
        view 
        resolutionExists(resolutionId) 
        returns (
            string memory description,
            uint256 startTime,
            uint256 endTime,
            Status status,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 votesAbstain
        ) 
    {
        Resolution storage resolution = resolutions[resolutionId];
        return (
            resolution.description,
            resolution.startTime,
            resolution.endTime,
            resolution.status,
            resolution.votesFor,
            resolution.votesAgainst,
            resolution.votesAbstain
        );
    }

    // Override requis
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
