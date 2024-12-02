// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ElectionSystem is ERC721URIStorage, Pausable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    
    enum Status { DRAFT, ACTIVE, CLOSED }
    enum Vote { NONE, POUR, CONTRE, ABSTENTION }
    
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

    mapping(uint256 => Resolution) public resolutions;
    mapping(uint256 => bool) public nftDistributed;
    uint256 public resolutionCounter;
    string private baseTokenURI;

    event ResolutionCreated(uint256 indexed resolutionId, string description);
    event ResolutionStatusChanged(uint256 indexed resolutionId, Status newStatus);
    event VoteRegistered(uint256 indexed resolutionId, address indexed voter, Vote choice);
    event VoterAdded(address indexed account);
    event VoterRemoved(address indexed account);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) 
        ERC721(_name, _symbol) 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseTokenURI = _baseURI;
        resolutionCounter = 0;
    }

    function addVoter(address _voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VOTER_ROLE, _voter);
        emit VoterAdded(_voter);
    }

    function removeVoter(address _voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VOTER_ROLE, _voter);
        emit VoterRemoved(_voter);
    }

    function addVoters(address[] calldata _voters) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_voters.length > 0, "Empty voters list");
        require(_voters.length <= 100, "Too many voters in single transaction");

        for (uint256 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            require(voter != address(0), "Invalid voter address");
            
            if (!hasRole(VOTER_ROLE, voter)) {
                grantRole(VOTER_ROLE, voter);
                emit VoterAdded(voter);
            }
        }
    }

    function removeVoters(address[] calldata _voters) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_voters.length > 0, "Empty voters list");
        require(_voters.length <= 100, "Too many voters in single transaction");

        for (uint256 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            require(voter != address(0), "Invalid voter address");
            
            if (hasRole(VOTER_ROLE, voter)) {
                revokeRole(VOTER_ROLE, voter);
                emit VoterRemoved(voter);
            }
        }
    }

    function isVoter(address _address) public view returns (bool) {
        return hasRole(VOTER_ROLE, _address);
    }

    function getVotersCount() public view returns (uint256) {
        return getRoleMemberCount(VOTER_ROLE);
    }

    function createResolution(
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_startTime >= block.timestamp, "Start time must be in the future");
        require(_endTime > _startTime, "End time must be after start time");

        resolutionCounter++;
        Resolution storage newResolution = resolutions[resolutionCounter];
        newResolution.description = _description;
        newResolution.startTime = _startTime;
        newResolution.endTime = _endTime;
        newResolution.status = Status.DRAFT;

        emit ResolutionCreated(resolutionCounter, _description);
    }

    function activateResolution(uint256 _resolutionId) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused 
    {
        Resolution storage resolution = resolutions[_resolutionId];
        require(resolution.status == Status.DRAFT, "Resolution is not in draft status");
        require(block.timestamp <= resolution.startTime, "Start time has passed");

        resolution.status = Status.ACTIVE;
        emit ResolutionStatusChanged(_resolutionId, Status.ACTIVE);
    }

    function vote(uint256 _resolutionId, Vote _choice) 
        public 
        onlyRole(VOTER_ROLE)
        whenNotPaused
        nonReentrant 
    {
        Resolution storage resolution = resolutions[_resolutionId];
        require(resolution.status == Status.ACTIVE, "Resolution is not active");
        require(block.timestamp >= resolution.startTime, "Voting has not started");
        require(block.timestamp <= resolution.endTime, "Voting has ended");
        require(_choice != Vote.NONE, "Invalid vote choice");
        require(resolution.voterChoices[msg.sender] == Vote.NONE, "Already voted");

        resolution.voterChoices[msg.sender] = _choice;

        if (_choice == Vote.POUR) {
            resolution.votePour = resolution.votePour.add(1);
        } else if (_choice == Vote.CONTRE) {
            resolution.voteContre = resolution.voteContre.add(1);
        } else {
            resolution.voteAbstention = resolution.voteAbstention.add(1);
        }

        _mintVoteNFT(msg.sender, _resolutionId);

        emit VoteRegistered(_resolutionId, msg.sender, _choice);
    }

    function closeResolution(uint256 _resolutionId) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused 
    {
        Resolution storage resolution = resolutions[_resolutionId];
        require(resolution.status == Status.ACTIVE, "Resolution is not active");
        require(block.timestamp > resolution.endTime, "Voting period has not ended");
        
        resolution.status = Status.CLOSED;
        emit ResolutionStatusChanged(_resolutionId, Status.CLOSED);
    }

    function _mintVoteNFT(address voter, uint256 resolutionId) internal {
        uint256 tokenId = totalSupply().add(1);
        _safeMint(voter, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, tokenId.toString())));
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
