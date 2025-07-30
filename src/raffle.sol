// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Raffle contract
 * @author Dharm Singh
 * @notice this contract is for creating a sample raffle
 * @dev  implement chainlink VRFv2.5
 */

contract Raffle {
    // errors
    error Raffle__NotEnoughEth();

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    event RaffleEnter(address indexed player);

    constructor(uint256 enteranceFee, uint256 interval) {
        i_entranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        //    require(msg.value >= i_entranceFee,"not enough ETH");
        //    require(msg.value >= i_entranceFee,Raffle__NotEnoughEth());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    // get a winner;
    // use random number to pick a player
    // be automatically called
    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
                  revert();
        }
        // get random number;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
