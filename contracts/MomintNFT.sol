// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MomintNFT is ERC721, Ownable {
    uint256 MAX_BATCH = 100000000; //100 000 000

    bool internal isAlive;
    bool internal isPause;

    uint256 private _nextMintId;

    struct BatchTokenInfo {
        uint256 amountOfBatch;
        uint256 amountMinted;
        uint256 lastMintedId; // Could be also a loop..
        string batchURI;
    }

    mapping(uint256 => BatchTokenInfo) private batchInfo_; // Origional token ID => batch info

    mapping(uint256 => uint256) private originalTokenId_;
    mapping(uint256 => uint256) private previoustInBatch_;

    mapping(uint256 => bool) private approveBurn_;

    constructor() ERC721("Momint", unicode"MOMINT ⏸") {
        _setBaseURI("ipfs://");
        isAlive = true;
        isPause = false;
    }

    event Batch(
        address indexed receiver, //needs indexed for easy log retrieval
        uint256 originalToken,
        uint256 amountOfBatch
    );

    modifier isContractActive() {
        require(isAlive && !isPause, "Contract deactivated");
        _;
    }

    /**
     * @param   receiver Address that will receive the token
     * @param   batchURI IPFS link for token content
     */
    function mintNft(
        address receiver,
        string memory batchURI,
        uint256 amountOfBatch
    ) public onlyOwner() isContractActive() returns (uint256) {
        require(amountOfBatch <= MAX_BATCH, "more than batch");
        require(amountOfBatch > 0, "must be over zero to mint");

        batchInfo_[_nextMintId].amountOfBatch = amountOfBatch;
        batchInfo_[_nextMintId].amountMinted = 1;
        batchInfo_[_nextMintId].lastMintedId = _nextMintId;
        batchInfo_[_nextMintId].batchURI = batchURI; // don't we want a baseURI ?

        originalTokenId_[_nextMintId] = _nextMintId;

        emit Batch(receiver, _nextMintId, amountOfBatch); // could be restrict if amountOfBatch > 1 ?

        _mint(receiver, _nextMintId);
        _nextMintId++;
        return (_nextMintId - 1);
    }

    function mintOneOfBatch(address receiver, uint256 originalId)
        external
        onlyOwner()
        isContractActive()
        returns (uint256)
    {
        require(!isBatch(originalId), "Need a originalTokenId as arg");
        require(
            batchInfo_[originalId].amountMinted <
                batchInfo_[originalId].amountOfBatch,
            "No more token mintable in batch"
        );

        previoustInBatch_[_nextMintId] = batchInfo_[originalId]
            .lastMintedId;

        batchInfo_[originalId].amountMinted++;
        batchInfo_[originalId].lastMintedId = _nextMintId;

        originalTokenId_[_nextMintId] = originalId;

        _mint(receiver, _nextMintId);
        _nextMintId++;
        return (_nextMintId - 1);
    }

       function mintManyOfBatch(address receiver, uint256 amount, uint256 originalId)
        external
        onlyOwner()
        isContractActive()
        returns (uint256[] memory)
    {
        require(!isBatch(originalId), "Need a originalTokenId as arg");
        require(
            batchInfo_[originalId].amountMinted + amount <=
                batchInfo_[originalId].amountOfBatch,
            "You cannot mint more tokens that the total batch amount"
        );

        uint256[] memory mintIds = new uint256[](amount);
        for(uint i = 0; i < amount; i = i + 1) {
             previoustInBatch_[_nextMintId] = batchInfo_[originalId]
            .lastMintedId;

            batchInfo_[originalId].amountMinted++;
            batchInfo_[originalId].lastMintedId = _nextMintId;

            originalTokenId_[_nextMintId] = originalId;

            _mint(receiver, _nextMintId);
            mintIds[i] = _nextMintId;
            _nextMintId++;
        }
        
        return mintIds;
    }

    function isBatch(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return originalTokenId_[tokenId] != tokenId;
    }

    function _baseURI(string baseURI)
        internal
        view
        override
        returns (string memory)
    {
        return "ipfs://";
    }

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

    function originalTokenId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return originalTokenId_[tokenId];
    }

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

    function _previousIdsPaginated(
        uint256 tokenId,
        uint256 amountToFetch,
        uint256[] memory _returnTokens
    ) private view returns (uint256[] memory) {
        uint256 currentToken = tokenId;
        uint256 originalToken = originalTokenId(tokenId);
        _returnTokens[amountToFetch-1]=currentToken;
        for(uint i = amountToFetch-1; i > 0; i = i - 1) {
            currentToken = previoustInBatch_[currentToken];
            _returnTokens[i-1] = currentToken;
            if(currentToken == originalToken) return _returnTokens;
        }
        return _returnTokens;
    }

    function getPreviousInBatch(uint256 tokenId) external view returns (uint256) {
        return previoustInBatch_[tokenId];
    }

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

    function batchTokenIdsPaginated(uint256 startTokenId, uint256 amountOfTokens)
        external
        view
        returns (uint256[] memory)
    {
        require(isBatch(startTokenId));
        return
        _previousIdsPaginated(
                startTokenId,
                amountOfTokens,
                new uint256[](amountOfTokens)
            );
    }

    function killContract() external onlyOwner() {
        isAlive = false;
    }

    /**
     * @param state The pause state of the contract
     * For us to pause this contract
     **/
    function pauseContract(bool state) external onlyOwner() {
        isPause = state;
    }

    /**
     * @param _tokenId The ID of the token
     * @param approve does the owner approve?
     */
    function approveBurn(uint256 _tokenId, bool approve) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        approveBurn_[_tokenId] = approve;
    }

    function burnTokenFrom(uint256 _tokenId) external onlyOwner() {
        require(approveBurn_[_tokenId], "Token not approved by owner");
        _burn(_tokenId);
    }
    // mainnet bridge?
}

// Test best praices
// Every function
// negative case of all modifers and requires
