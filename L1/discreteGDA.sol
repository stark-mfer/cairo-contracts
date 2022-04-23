// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IStarknetCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stark is ERC721, Ownable {
    uint256 public tokenCounter;
    IStarknetCore constant starknetCore = IStarknetCore(0xD384D7153D17EcB8cdf47300dBAD70b60b7C7826);
    uint256 public l2Contract;
    uint256 public CLAIM_SELECTOR;
    uint256 public BRIDGE_SELECTOR;

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC721(_name, _symbol) {
        tokenCounter = 0;
    }

    function setClaimSelector(uint256 _claimSelector) external onlyOwner {
        CLAIM_SELECTOR = _claimSelector;
    }

    function setEvaluatorContractAddress(uint256 _evaluatorContractAddress) external onlyOwner {
        EvaluatorContractAddress = _evaluatorContractAddress;
    }

    function setL2Contract(uint256 _l2) external onlyOwner {
        l2Contract = _l2;
    }

    function bridgeFromL2(uint256 l2User, address recipient, uint256 tokenId) external {
        uint256[] memory payload = new uint256[](3);
        payload[0] = l2User;
        payload[1] = uint256(uint160(recipient));
        payload[2] = tokenId;
        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2Contract, payload);
        _safeMint(address(uint160(msg.sender)), tokenCounter);
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            l2Contract,
            CLAIM_SELECTOR,
            payload
        );
    }

    function bridgeToL2(uint256 l2User, uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "not owner/approved");
        _burn(tokenId);

        uint256[] memory payload = new uint256[](2);
        payload[0] = l2User;
        payload[1] = tokenId;

        starknetCore.sendMessageToL2(l2Contract, BRIDGE_SELECTOR, payload);
    }
}
