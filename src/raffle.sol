// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {VRFConsumerBaseV2Plus} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {IVRFCoordinatorV2Plus} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "../lib/forge-std/src/console.sol";
/**
 *
 * @title Raffle contract
 * @author Dharm Singh
 * @notice this contract is for creating a sample raffle
 * @dev  implement chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // errors
    error Raffle__NotEnoughEth();
    error Raffle__TransferFailed();
    error Raffle_NotOpen();
    error Raffle_CheckUpKeepNotNeeded(uint256 balance , uint256 players , uint256 raffleState);

    //    typeDeclation
    enum RaffleState {
        OPEN, // 0
        CALCULATING //1
    }

    // state variable
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;

    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEnter(address indexed player);
    event winnerPicked(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        //    require(msg.value >= i_entranceFee,"not enough ETH");
        //    require(msg.value >= i_entranceFee,Raffle__NotEnoughEth());

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_NotOpen();
        }

        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    // when should the winner picked?

    function checkUpkeep(
        bytes memory /* CheckData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded =timeHasPassed && isOpen &&hasBalance && hasPlayers;

        return (upkeepNeeded,"");
    }

    // get a winner;
    // use random number to pick a player
    // be automatically called
    function performUpkeep(bytes calldata /* performData */) external  {
       (bool upkeepNeeded, ) = checkUpkeep("");
       console.log("INside performUp keep");
       if(!upkeepNeeded){
        revert Raffle_CheckUpKeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
       }        
        s_raffleState = RaffleState.CALCULATING;
        // get random number;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    //    CEI : checks ,Effects ,Interaction pattern

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable reacentWinner = s_players[indexOfWinner];
        s_recentWinner = reacentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = reacentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit winnerPicked(s_recentWinner);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external  view returns(RaffleState) {
        return s_raffleState;
    }

    function getPlayers(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    } 
}
