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
    enum ResolutionStatus { DRAFT, ACTIVE, CLOSED, NONE }

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
    event ResolutionStatusUpdated(uint256 indexed resolutionId, ResolutionStatus newStatus);

    // Erreurs personnalisées
    error InvalidTimeRange();
    error EmptyString();
    error InvalidStatus();
    error Unauthorized();

    constructor(
        string memory name,
        string memory symbol,
        uint256 _minimumTokensRequired,
        string memory certificateBaseURI
    ) ERC721(name, symbol) {
        require(_minimumTokensRequired > 0, "Minimum tokens must be greater than 0");
        require(bytes(certificateBaseURI).length > 0, "Base URI cannot be empty");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        minimumTokensRequired = _minimumTokensRequired;
        _certificateBaseURI = certificateBaseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function configureAssembly(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(_title).length == 0 || bytes(_description).length == 0) revert EmptyString();
        if (_startTime <= block.timestamp || _endTime <= _startTime) revert InvalidTimeRange();
        
        assemblyTitle = _title;
        assemblyDescription = _description;
        assemblyStartTime = _startTime;
        assemblyEndTime = _endTime;

        emit AssemblyConfigured(_title, _startTime, _endTime);
    }

    function createResolution(
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(title).length == 0 || bytes(description).length == 0) revert EmptyString();
        if (startTime < assemblyStartTime || endTime > assemblyEndTime) revert InvalidTimeRange();

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

    function updateResolutionStatus(
        uint256 resolutionId,
        ResolutionStatus newStatus
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Resolution storage resolution = resolutions[resolutionId];
        if (newStatus == ResolutionStatus.NONE) revert InvalidStatus();
        
        resolution.status = newStatus;
        emit ResolutionStatusUpdated(resolutionId, newStatus);
    }

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

    function getResolutionDetails(uint256 resolutionId)
        external
        view
        returns (
            string memory title,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            ResolutionStatus status,
            uint256 votesPour,
            uint256 votesContre,
            uint256 votesAbstention
        )
    {
        Resolution storage resolution = resolutions[resolutionId];
        return (
            resolution.title,
            resolution.description,
            resolution.startTime,
            resolution.endTime,
            resolution.status,
            resolution.votesPour,
            resolution.votesContre,
            resolution.votesAbstention
        );
    }

    function issueVoteCertificate(address voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(voter, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_certificateBaseURI, tokenId.toString())));
        _tokenIdCounter.increment();

        emit VoteCertificateIssued(voter, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _certificateBaseURI;
    }

    // Fonctions de pause
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
