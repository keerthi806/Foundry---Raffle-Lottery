// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import{Script} from "forge-std/Script.sol";
import{Raffle} from "src/Raffle.sol";
import{HelperConfig} from "./HelperConfig.s.sol";
import{CreateSubscription,FundSubscription,AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script{
    function run() public{}

    function deployContract() external returns(Raffle,HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // subscriptionId needed to employ VRF
        if(config.subscriptionId == 0){
            // Create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);

            // Fund it
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }
    
        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Contract should be deployed; only then we can get a consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
        // Don't need to broadcast, since addConsumer() has it

        return(raffle, helperConfig);
    }
}