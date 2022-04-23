// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStarknetCore.sol";

contract L1MintL2Nft is Ownable {
    IStarknetCore starknetCore;
    uint256 private evaluatorContractAddress;
    uint256 private selector;

    constructor(
        address _starknetCore,
        uint256 _evaluatorContractAddress,
        uint256 _selector
    ) {
        starknetCore = IStarknetCore(_starknetCore);
        evaluatorContractAddress = _evaluatorContractAddress;
        selector = _selector;
    }

    // Exercise 2
    function createNftFromL1(uint256 l2User) external {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        // Sends a message to L2
        starknetCore.sendMessageToL2(
            evaluatorContractAddress,
            selector,
            payload
        );
    }

    // Exercise 3
    function consumeMessage(uint256 l2ContractAddress, uint256 l2User)
        external
    {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        // Receives a message from L2
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
    }
}
