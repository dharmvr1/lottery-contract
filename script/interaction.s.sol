// SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstant} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/linkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, CodeConstant {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinates = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(
            vrfCoordinates,
            helperConfig.getConfig().acount
        );
        return (subId, vrfCoordinates);
    }

    function createSubscription(
        address vrfCoordinate,
        address account
    ) public returns (uint256, address) {
        console.log("Creating subs on chain Id:", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinate)
            .createSubscription();
        vm.stopBroadcast();
        console.log("subscription ID is:", subId);
        return (subId, vrfCoordinate);
    }

    function run() external {
        CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstant {
    uint256 public constant FUND_AMOUNT = 300 ether; //3link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helpConfig = new HelperConfig();
        address vrfCoordinate = helpConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helpConfig.getConfig().subscriptionId;
        address linkToken = helpConfig.getConfig().link;
        address account = helpConfig.getConfig().acount;

        fundSubscription(vrfCoordinate, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfCoordinate,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console.log("funding subscriptionId", subscriptionId);
        console.log("funding vrfCoordinate", vrfCoordinate);
        console.log("on ChainId", block.chainid);

        if (block.chainid == LOCAL_CHAINID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinate).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinate,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );

            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script, CodeConstant {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().acount;
        // address linkToken = helperConfig.getConfig().link;
        addConsumer(
            mostRecentlyDeployed,
            vrfCoordinator,
            subscriptionId,
            account
        );
    }

    function addConsumer(
        address contractToAddVrf,
        address vrfCoordinate,
        uint256 subId,
        address account
    ) public {
        console.log("funding subscriptionId", subId);
        console.log("funding vrfCoordinate", vrfCoordinate);
        console.log("on ChainId", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinate).addConsumer(
            subId,
            contractToAddVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
