// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ElectionSystem is AccessControl, ReentrancyGuard, ERC721URIStorage, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Compteurs
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _resolutionCounter;

    // URI de base pour les certificats
    string private _certificateBaseURI;

    // Rôles
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    // Énumérations
    enum VoteChoice { NONE, POUR, CONTRE, ABSTENTION }
    enum ResolutionStatus { DRAFT, ACTIVE, CLOSED }

    // Structures
    struct Resolution {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        ResolutionStatus status;
        uint256 votesPour;
        uint256 votesContre;
        uint256 votesAbstention;
        mapping(address => bool) hasVoted;
        mapping(address => VoteChoice) voterChoices;
    }

    struct VoteRecord {
        uint256 resolutionId;
        VoteChoice choice;
        uint256 timestamp;
    }

    // Variables d'état
    mapping(uint256 => Resolution) public resolutions;
    mapping(address => VoteRecord[]) public voterHistory;
    uint256 public assemblyStartTime;
    uint256 public assemblyEndTime;
    string public assemblyTitle;
    string public assemblyDescription;
    uint256 public minimumTokensRequired;

    // Événements
    event ResolutionCreated(uint256 indexed resolutionId, string title);
    event VoteCast(uint256 indexed resolutionId, address indexed voter, VoteChoice choice);
    event VoteCertificateIssued(address indexed voter, uint256 tokenId);
    event AssemblyConfigured(string title, uint256 startTime, uint256 endTime);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _minimumTokensRequired,
        string memory certificateBaseURI
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        minimumTokensRequired = _minimumTokensRequired;
        _certificateBaseURI = certificateBaseURI;
    }

    // Configuration de l'assemblée
    function configureAssembly(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(_endTime > _startTime, "End time must be after start time");
        
        assemblyTitle = _title;
        assemblyDescription = _description;
        assemblyStartTime = _startTime;
        assemblyEndTime = _endTime;

        emit AssemblyConfigured(_title, _startTime, _endTime);
    }

    // Création d'une résolution
    function createResolution(
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startTime >= assemblyStartTime, "Start time before assembly start");
        require(endTime <= assemblyEndTime, "End time after assembly end");

        uint256 resolutionId = _resolutionCounter.current();
        Resolution storage newResolution = resolutions[resolutionId];
        
        newResolution.title = title;
        newResolution.description = description;
        newResolution.startTime = startTime;
        newResolution.endTime = endTime;
        newResolution.status = ResolutionStatus.DRAFT;

        _resolutionCounter.increment();
        emit ResolutionCreated(resolutionId, title);
    }

    // Vote sur une résolution
    function vote(
        uint256 resolutionId,
        VoteChoice choice
    ) external whenNotPaused nonReentrant onlyRole(VOTER_ROLE) {
        Resolution storage resolution = resolutions[resolutionId];
        
        require(resolution.status == ResolutionStatus.ACTIVE, "Resolution not active");
        require(block.timestamp >= resolution.startTime, "Voting not started");
        require(block.timestamp <= resolution.endTime, "Voting ended");
        require(!resolution.hasVoted[msg.sender], "Already voted");
        require(choice != VoteChoice.NONE, "Invalid vote choice");

        resolution.hasVoted[msg.sender] = true;
        resolution.voterChoices[msg.sender] = choice;

        if (choice == VoteChoice.POUR) {
            resolution.votesPour++;
        } else if (choice == VoteChoice.CONTRE) {
            resolution.votesContre++;
        } else {
            resolution.votesAbstention++;
        }

        voterHistory[msg.sender].push(VoteRecord({
            resolutionId: resolutionId,
            choice: choice,
            timestamp: block.timestamp
        }));

        emit VoteCast(resolutionId, msg.sender, choice);
    }
}
