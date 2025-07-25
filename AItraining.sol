// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Collective AI Model Training Rewards
 * @dev A decentralized protocol for incentivizing AI model training contributions
 * @author AI Training DAO
 */
contract CollectiveAITraining {
    
    // State variables
    address public owner;
    uint256 public totalRewardsPool;
    uint256 public minimumStake;
    uint256 public contributionCounter;
    
    // Structs
    struct Contributor {
        address contributorAddress;
        uint256 stakedAmount;
        uint256 totalContributions;
        uint256 reputationScore;
        uint256 totalRewardsEarned;
        bool isActive;
    }
    
    struct Contribution {
        uint256 contributionId;
        address contributor;
        ContributionType contributionType;
        string dataHash; // IPFS hash for datasets or computation proof
        uint256 qualityScore;
        uint256 rewardAmount;
        uint256 timestamp;
        bool validated;
    }
    
    enum ContributionType {
        ComputePower,
        Dataset,
        Validation
    }
    
    // Mappings
    mapping(address => Contributor) public contributors;
    mapping(uint256 => Contribution) public contributions;
    mapping(address => bool) public validators;
    
    // Events
    event ContributorRegistered(address indexed contributor, uint256 stakedAmount);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, ContributionType contributionType);
    event RewardDistributed(address indexed contributor, uint256 amount);
    event ContributionValidated(uint256 indexed contributionId, uint256 qualityScore);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyValidator() {
        require(validators[msg.sender], "Only validators can call this function");
        _;
    }
    
    modifier onlyActiveContributor() {
        require(contributors[msg.sender].isActive, "Contributor not active");
        _;
    }
    
    constructor(uint256 _minimumStake) {
        owner = msg.sender;
        minimumStake = _minimumStake;
        contributionCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Register as a contributor by staking tokens
     * @notice Contributors must stake minimum amount to participate
     */
    function registerContributor() external payable {
        require(msg.value >= minimumStake, "Insufficient stake amount");
        require(!contributors[msg.sender].isActive, "Already registered");
        
        contributors[msg.sender] = Contributor({
            contributorAddress: msg.sender,
            stakedAmount: msg.value,
            totalContributions: 0,
            reputationScore: 100, // Starting reputation
            totalRewardsEarned: 0,
            isActive: true
        });
        
        emit ContributorRegistered(msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 2: Submit contributions (compute power, datasets, or validation)
     * @param _contributionType Type of contribution being submitted
     * @param _dataHash IPFS hash or proof of contribution
     */
    function submitContribution(
        ContributionType _contributionType,
        string memory _dataHash
    ) external onlyActiveContributor {
        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        
        contributionCounter++;
        
        contributions[contributionCounter] = Contribution({
            contributionId: contributionCounter,
            contributor: msg.sender,
            contributionType: _contributionType,
            dataHash: _dataHash,
            qualityScore: 0,
            rewardAmount: 0,
            timestamp: block.timestamp,
            validated: false
        });
        
        contributors[msg.sender].totalContributions++;
        
        emit ContributionSubmitted(contributionCounter, msg.sender, _contributionType);
    }
    
    /**
     * @dev Core Function 3: Distribute rewards based on contribution quality and type
     * @param _contributionId ID of the contribution to reward
     * @param _qualityScore Quality score assigned by validators (1-100)
     */
    function distributeRewards(
        uint256 _contributionId,
        uint256 _qualityScore
    ) external onlyValidator {
        require(_contributionId <= contributionCounter, "Invalid contribution ID");
        require(_qualityScore >= 1 && _qualityScore <= 100, "Quality score must be between 1-100");
        
        Contribution storage contribution = contributions[_contributionId];
        require(!contribution.validated, "Contribution already validated");
        
        // Calculate reward based on contribution type and quality score
        uint256 baseReward = calculateBaseReward(contribution.contributionType);
        uint256 rewardAmount = (baseReward * _qualityScore) / 100;
        
        // Update contribution
        contribution.qualityScore = _qualityScore;
        contribution.rewardAmount = rewardAmount;
        contribution.validated = true;
        
        // Update contributor stats
        address contributorAddr = contribution.contributor;
        contributors[contributorAddr].totalRewardsEarned += rewardAmount;
        contributors[contributorAddr].reputationScore = 
            (contributors[contributorAddr].reputationScore + _qualityScore) / 2;
        
        // Transfer reward (in a real implementation, this would use ERC20 tokens)
        totalRewardsPool += rewardAmount;
        
        emit ContributionValidated(_contributionId, _qualityScore);
        emit RewardDistributed(contributorAddr, rewardAmount);
    }
    
    /**
     * @dev Calculate base reward amount based on contribution type
     * @param _type Type of contribution
     * @return Base reward amount in wei
     */
    function calculateBaseReward(ContributionType _type) internal pure returns (uint256) {
        if (_type == ContributionType.ComputePower) {
            return 1 ether; // Higher reward for compute power
        } else if (_type == ContributionType.Dataset) {
            return 0.5 ether; // Medium reward for datasets
        } else {
            return 0.2 ether; // Lower reward for validation
        }
    }
    
    // Additional utility functions
    
    /**
     * @dev Add a validator to the system
     * @param _validator Address to be added as validator
     */
    function addValidator(address _validator) external onlyOwner {
        validators[_validator] = true;
    }
    
    /**
     * @dev Remove a validator from the system
     * @param _validator Address to be removed as validator
     */
    function removeValidator(address _validator) external onlyOwner {
        validators[_validator] = false;
    }
    
    /**
     * @dev Get contribution details
     * @param _contributionId ID of the contribution
     * @return contributor Address of the contributor
     * @return contributionType Type of contribution (ComputePower, Dataset, Validation)
     * @return dataHash IPFS hash of the contribution data
     * @return qualityScore Quality score assigned by validators (0-100)
     * @return rewardAmount Amount of rewards earned
     * @return validated Whether the contribution has been validated
     */
    function getContribution(uint256 _contributionId) external view returns (
        address contributor,
        ContributionType contributionType,
        string memory dataHash,
        uint256 qualityScore,
        uint256 rewardAmount,
        bool validated
    ) {
        Contribution memory contribution = contributions[_contributionId];
        return (
            contribution.contributor,
            contribution.contributionType,
            contribution.dataHash,
            contribution.qualityScore,
            contribution.rewardAmount,
            contribution.validated
        );
    }
    
    /**
     * @dev Get contributor details
     * @param _contributor Address of the contributor
     * @return stakedAmount Amount of tokens staked by the contributor
     * @return totalContributions Total number of contributions made
     * @return reputationScore Current reputation score (0-100)
     * @return totalRewardsEarned Total rewards earned to date
     * @return isActive Whether the contributor is currently active
     */
    function getContributor(address _contributor) external view returns (
        uint256 stakedAmount,
        uint256 totalContributions,
        uint256 reputationScore,
        uint256 totalRewardsEarned,
        bool isActive
    ) {
        Contributor memory contributor = contributors[_contributor];
        return (
            contributor.stakedAmount,
            contributor.totalContributions,
            contributor.reputationScore,
            contributor.totalRewardsEarned,
            contributor.isActive
        );
    }
    
    /**
     * @dev Update minimum stake requirement
     * @param _newMinimumStake New minimum stake amount
     */
    function updateMinimumStake(uint256 _newMinimumStake) external onlyOwner {
        minimumStake = _newMinimumStake;
    }
    
    /**
     * @dev Emergency function to pause contributor registration
     * @param _contributor Address of contributor to deactivate
     */
    function deactivateContributor(address _contributor) external onlyOwner {
        contributors[_contributor].isActive = false;
    }
    
    /**
     * @dev Get total number of contributions
     * @return Total contributions count
     */
    function getTotalContributions() external view returns (uint256) {
        return contributionCounter;
    }
    
    /**
     * @dev Withdraw contract balance (owner only)
     */
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Fallback function to receive Ether
    receive() external payable {
        totalRewardsPool += msg.value;
    }
}
