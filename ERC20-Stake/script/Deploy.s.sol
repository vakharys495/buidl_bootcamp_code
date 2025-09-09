// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol"; // Add this import
import {WereyCoin} from "../src/WereyCoin.sol";
import {WereyStaking} from "../src/WereyStaking.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("b5fe85e1bf0e73eaf36eba8cb4b1ee193affe865379d95c42783a459b0c8e952");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WereyCoin (token recipient is deployer, owner is deployer)
        WereyCoin token = new WereyCoin(msg.sender, msg.sender); // Use msg.sender for deployer
        console.log("WereyCoin deployed at:", address(token));

        // Deploy WereyStaking with token address
        WereyStaking staking = new WereyStaking(address(token), msg.sender);
        console.log("WereyStaking deployed at:", address(staking));

        vm.stopBroadcast();
    }
}