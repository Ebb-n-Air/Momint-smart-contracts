// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @dev  Interface for interacting with an ERC20 token
*/
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

contract MomintNFT is ERC721, Ownable {
    uint256 MAX_BATCH = 100000; //100 000 maximum tokens in a batch

    bool internal isAlive; // Not relevant to your smart contract, but required by this one
    bool internal isPause; // Not relevant to your smart contract, but required by this one
    uint256 private _nextMintId; //utility to track what token number we are currently on

    struct BatchTokenInfo {
        address[] batchTokenHolders;
        uint256 amountOfBatch;
        uint256 amountMinted;
        uint256 lastMintedId;
        string batchURI;
    } // stores the batch info for a given batch

    mapping(uint256 => BatchTokenInfo) private batchInfo_; // Original token ID => batch info
    mapping(uint256 => uint256) private originalTokenId_;
    mapping(uint256 => uint256) private previoustInBatch_;
    mapping(uint256 => bool) private approveBurn_;

    constructor() ERC721("Momint", unicode"MOMINT ⏸") {
        isAlive = true;
        isPause = false;
    }

    event Batch(
        address indexed receiver,
        uint256 originalToken,
        uint256 amountOfBatch
    );

    /**
        Can be used to chewck that the contract is still active before doing anything
     */
    modifier isContractActive() {
        require(isAlive && !isPause, "Contract deactivated");
        _;
    }

    /**
     * Mint a single token that is also a batch (ie. a 1 of 1)
     * @param   receiver Address that will receive the token
     * @param   batchURI IPFS link for token content
     * @return the tokenID of the minted token
     */
    function mintNft(
        address receiver,
        string memory batchURI,
        uint256 amountOfBatch
    ) public onlyOwner isContractActive returns (uint256) {
        require(amountOfBatch < MAX_BATCH, "more than batch");
        require(amountOfBatch > 0, "must be over zero to mint");

        batchInfo_[_nextMintId].batchTokenHolders.push(receiver);
        batchInfo_[_nextMintId].amountOfBatch = amountOfBatch;
        batchInfo_[_nextMintId].amountMinted = 1;
        batchInfo_[_nextMintId].lastMintedId = _nextMintId;
        batchInfo_[_nextMintId].batchURI = batchURI;
        originalTokenId_[_nextMintId] = _nextMintId;

        emit Batch(receiver, _nextMintId, amountOfBatch);

        _mint(receiver, _nextMintId);
        _nextMintId++;
        return (_nextMintId - 1);
    }

    /**
     * Mint a single token that is in a batch (ie. a 1 of many)
     * @param   receiver Address that will receive the token
     * @param   originalId the tokenID of the batched 'parent' token
     * @return the tokenID of the minted token
     */
    function mintOneOfBatch(address receiver, uint256 originalId)
        external
        onlyOwner
        isContractActive
        returns (uint256)
    {
        require(!isBatch(originalId), "Need a originalTokenId as arg");
        require(
            batchInfo_[originalId].amountMinted <
                batchInfo_[originalId].amountOfBatch,
            "No more token mintable in batch"
        );

        previoustInBatch_[_nextMintId] = batchInfo_[originalId].lastMintedId;
        batchInfo_[originalId].amountMinted++;
        batchInfo_[originalId].lastMintedId = _nextMintId;
        batchInfo_[originalId].batchTokenHolders.push(receiver);
        originalTokenId_[_nextMintId] = originalId;

        _mint(receiver, _nextMintId);
        _nextMintId++;
        return (_nextMintId - 1);
    }

    /**
     * Gets all of the addresses associated with a specific batch
     * @param   tokenId the tokenID of supposed 'parent' token
     * @return returns the addresses mentioned above
     */
    function getTokenOwnersOfBatch(uint256 tokenId) public view returns (address[] memory) {
        return batchInfo_[tokenId].batchTokenHolders;
    }

    /**
     * This function pays out the accounts associated witha  specific batch in ETH
     * @param   tokenId the tokenID of supposed 'parent' token
     */
    function payBatchTokenHoldersInEth(uint256 tokenId) external payable {
        uint256 numBatchTokenHolders = getTokenOwnersOfBatch(tokenId).length;
        uint256 amount = msg.value / numBatchTokenHolders;
        for(uint256 i = 0; i < numBatchTokenHolders; i++) {
            address batchTokenHolder = batchInfo_[tokenId].batchTokenHolders[i];
            payable(batchTokenHolder).transfer(amount);
        }
    }

    /**
     * This function pays out the accounts associated witha  specific batch in the associated ERC20 token of a batch
     * @param   tokenId the tokenID of supposed 'parent' token
     * @param   token the address of the ERC20 token to be transferred
     * @param   amountOfToken the amount of said ERC20 token to be transferred
     */
    function payBatchTokenHoldersInERC20(uint256 tokenId, IERC20 token, uint256 amountOfToken) external {
        uint numBatchTokenHolders = getTokenOwnersOfBatch(tokenId).length;
        uint amount = amountOfToken * 10 ** 18;
        uint amountToTransfer = amount / numBatchTokenHolders;
        for(uint256 i = 0; i < numBatchTokenHolders; i++) {
            address batchTokenHolder = batchInfo_[tokenId].batchTokenHolders[i];
            token.transferFrom(msg.sender, batchTokenHolder, amountToTransfer);
        }
    }

    /**
     * Checks if the token is the 'parent' token of a batch, ie. the first token minted in the batch used as the template for the other editions
     * @param   tokenId the tokenID of supposed 'parent' token
     * @return return true if the token is actually the 'parent' token of a batch
     */
    function isBatch(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return originalTokenId_[tokenId] != tokenId;
    }

    /**
     * Get tokenUri (ie. the asset) of a given token
     * @param   tokenId the tokenID of the token
     * @return batchURI a string URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isBatch(tokenId)) {
            return tokenURI(originalTokenId_[tokenId]);
        }
        return batchInfo_[tokenId].batchURI;
    }

    /**
     * Gets the 'parent' tokenID of the batch that a given tokenID sits in
     * @param   tokenId the tokenID of the token
     * @return originalTokenId_ the parent tokenID
     */
    function originalTokenId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return originalTokenId_[tokenId];
    }

    /** Get general info on the token batch
     */
    function batchInfo(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (isBatch(tokenId)) {
            return batchInfo(originalTokenId_[tokenId]);
        }
        return (
            batchInfo_[tokenId].amountOfBatch,
            batchInfo_[tokenId].amountMinted,
            batchInfo_[tokenId].lastMintedId
        );
    }

    /** Get the owners wallet address
     */
    function batchOwner(uint256 tokenId) external view returns (address) {
        require(isBatch(tokenId));
        return ownerOf(originalTokenId_[tokenId]);
    }

    function _previousIds(
        uint256 tokenId,
        uint256 i,
        uint256[] memory _tmp
    ) private view returns (uint256[] memory) {
        if (isBatch(tokenId)) {
            _previousIds(previoustInBatch_[tokenId], i - 1, _tmp);
            _tmp[i - 1] = tokenId;
            return _tmp;
        }
        _tmp[0] = tokenId;
        return _tmp;
    }

    /** Get an array of all the tokens in a batch (not they are not necisarrily sequential)
     */
    function batchTokenIds(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return
            _previousIds(
                batchInfo_[originalTokenId(tokenId)].lastMintedId,
                batchInfo_[originalTokenId(tokenId)].amountMinted,
                new uint256[](batchInfo_[originalTokenId(tokenId)].amountMinted)
            );
    }

    /** Kill the contract
     */
    function killContract() external onlyOwner {
        isAlive = false;
    }

    /**
     * @param state The pause state of the contract
     * For us to pause this contract
     **/
    function pauseContract(bool state) external onlyOwner {
        isPause = state;
    }

    /** Approve burning of a token
     * @param _tokenId The ID of the token
     * @param approve does the owner approve?
     */
    function approveBurn(uint256 _tokenId, bool approve) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        approveBurn_[_tokenId] = approve;
    }

    /** Burn a token
     */
    function burnTokenFrom(uint256 _tokenId) external onlyOwner {
        require(approveBurn_[_tokenId], "Token not approved by owner");
        _burn(_tokenId);
    }
    // mainnet bridge?
}

