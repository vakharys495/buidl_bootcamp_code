// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WereyStaking is ERC721, Ownable {
    ERC20 public immutable STAKING_TOKEN; // WereyCoin ERC20 token
    uint256 public tokenIdCounter; // Counter for NFT token IDs

    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 startTime; // Timestamp when stake was made
        uint256 duration; // Staking duration in seconds
        bool claimed; // Whether the reward has been claimed
    }

    // Mapping of user address to their stakes
    mapping(address => Stake[]) public stakes;

    // Event declarations
    event Staked(address indexed user, uint256 amount, uint256 duration, uint256 startTime);
    event Unstaked(address indexed user, uint256 amount, uint256 tokenId);
    event RewardClaimed(address indexed user, uint256 tokenId);

    constructor(address _stakingToken, address initialOwner)
        ERC721("WereyStakingNFT", "WSNFT")
        Ownable(initialOwner)
    {
        STAKING_TOKEN = ERC20(_stakingToken);
        tokenIdCounter = 1;
    }

    // Function to stake tokens
    function stake(uint256 amount, uint256 duration) external {
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        // Transfer tokens from user to contract
        require(STAKING_TOKEN.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Record the stake
        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: block.timestamp,
            duration: duration,
            claimed: false
        }));

        emit Staked(msg.sender, amount, duration, block.timestamp);
    }

    // Function to unstake and claim NFT reward
    function unstake(uint256 stakeIndex) external {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(!userStake.claimed, "Reward already claimed");
        require(block.timestamp >= userStake.startTime + userStake.duration, "Staking period not ended");

        // Mark stake as claimed
        userStake.claimed = true;

        // Mint NFT reward
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;
        _safeMint(msg.sender, tokenId);

        // Return staked tokens
        require(STAKING_TOKEN.transfer(msg.sender, userStake.amount), "Token return failed");

        emit Unstaked(msg.sender, userStake.amount, tokenId);
        emit RewardClaimed(msg.sender, tokenId);
    }

    // Function to get user's stakes
    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    // Function to check if stake is ready to claim
    function canClaim(address user, uint256 stakeIndex) external view returns (bool) {
        if (stakeIndex >= stakes[user].length) {
            return false;
        }
        Stake memory userStake = stakes[user][stakeIndex];
        return !userStake.claimed && block.timestamp >= userStake.startTime + userStake.duration;
    }

}