// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract MomintNFT is ERC721, Ownable {
    uint256 MAX_BATCH = 100000; //100 000 maximum tokens in a batch

    bool internal isAlive; // Not relevant to your smart contract, but required by this one
    bool internal isPause; // Not relevant to your smart contract, but required by this one
    uint256 private _nextMintId; //utility to track what token number we are currently on

    struct BatchTokenInfo {
        uint256 amountOfBatch;
        uint256 amountMinted;
        uint256 lastMintedId;
        string batchURI;

        address erc20tokenAddress; // Address of the ERC20 token deposited into the batch
        uint256 ethDepositId; // Id of the specific deposit in ETH
        uint256 erc20DepositId; // Id of the specific deposit in ERC20
        mapping(uint256 => mapping(uint256 => uint256)) ethDepositBalance; // Amount of eth deposited for a given batch
        mapping(uint256 => mapping(uint256 => uint256)) erc20DepositBalance; // Amount of ERC20 tokens deposited for a given batch
        mapping(uint256 => mapping(address => bool)) hasWithdrawnForIdAndEth; // Keeps track of addresses who have alread withdrawn from deposits in ETH
        mapping(uint256 => mapping(address => bool)) hasWithdrawnForIdAndERC20; // Keeps track of addresses who have alread withdrawn from deposits in ERC20
        mapping(address => bool) isTokenHolder; // Keeps track of whether or not an address is a token holder
        mapping(address => uint) indexOf; // Keeps track of the indexes of token holders
        address[] tokenHolders; // Stores the token holders of a specific batch
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
     * Adds a specific token holder to a new batch
     * @param   receiver The address to be added to the batch
     */
    function _addTokenHolderToNewBatch(
        address receiver
    ) internal {
        batchInfo_[_nextMintId].indexOf[receiver] = batchInfo_[_nextMintId].tokenHolders.length;
        batchInfo_[_nextMintId].tokenHolders.push(receiver);
    }

    /**
     * Adds a specific token holder to an existing batch
     * @param   receiver The address to be added to the batch
     * @param   originalId The ID of the parant token
     */
    function _addTokenHolderToExistingBatch(
        address receiver,
        uint256 originalId
    ) internal {
        batchInfo_[originalId].indexOf[receiver] = batchInfo_[originalId].tokenHolders.length;
        batchInfo_[originalId].tokenHolders.push(receiver);
    }

    /**
     * Removes a specific token holder from a batch
     * @param   tokenHolder The address to be removed
     * @param   tokenId The Id of the NFT held by the token holder
     */
    function _removeTokenHolderFromBatch(
        address tokenHolder,
        uint256 tokenId
    ) internal {
        uint originalId = originalTokenId(tokenId);
        uint256 index = batchInfo_[originalId].indexOf[tokenHolder];
        uint256 lastIndex = batchInfo_[originalId].tokenHolders.length - 1;
        address lastTokenHolder = batchInfo_[originalId].tokenHolders[lastIndex];

        batchInfo_[originalId].indexOf[lastTokenHolder] = index;
        delete batchInfo_[originalId].indexOf[tokenHolder];

        batchInfo_[originalId].tokenHolders[index] = lastTokenHolder;
        batchInfo_[originalId].tokenHolders.pop();
    }

    /**
     * Gets a list of addresses, which hold tokens of a specifc batch
     * @param   originalId The ID of the parant token of the batch
     * @return   Returns a list of addresses, which hold tokens of a specific batch
     */
    function getBatchTokenHolders(uint256 originalId) external view returns (address[] memory) {
        return batchInfo_[originalId].tokenHolders;
    }

    /**
     * Pay the token holders of a specific batch in ETH
     * @param   originalId The ID of the parant token of the batch
     */
    function payBatchInEth(uint256 originalId) external payable {
        uint256 ethDepositId = batchInfo_[originalId].ethDepositId;
        batchInfo_[originalId].ethDepositBalance[originalId][ethDepositId] = msg.value;
        batchInfo_[originalId].ethDepositId++;
    }

    /**
     * Pay the token holders of a specific batch in ERC20 tokens
     * @param   token The address of the ERC20 token to be uses
     * @param   _amount The amount of ERC20 tokens to be deposited
     * @param   originalId The ID of the parant token of the batch
     */
    function payBatchInERC20(IERC20 token, uint256 _amount, uint256 originalId) external {
        uint256 amount = _amount * 10 ** 18;
        uint256 erc20DepositId = batchInfo_[originalId].erc20DepositId;
        batchInfo_[originalId].erc20tokenAddress = address(token);
        batchInfo_[originalId].erc20DepositBalance[originalId][erc20DepositId] = amount;
        token.transferFrom(msg.sender, address(this), amount);
        batchInfo_[originalId].erc20DepositId++;
    }

    /**
     * Withdraw all of the ETH for a specific deposit and receiver
     * @param   originalId ID of the parent token of a batch
     * @param   ethDepositId The ID of the deposited ETH (first deposit will have ID of zero, second ID of 1 and so on)
     */
    function withdrawEth(uint256 originalId, uint256 ethDepositId) external {
        require(batchInfo_[originalId].isTokenHolder[msg.sender] == true, "Not a batch token holder");
        require(batchInfo_[originalId].hasWithdrawnForIdAndEth[ethDepositId][msg.sender] == false, "You have already withdrawn ETH");
        uint256 numTokenHoldersInBatch = batchInfo_[originalId].tokenHolders.length;
        uint256 amount = batchInfo_[originalId].ethDepositBalance[originalId][ethDepositId];
        uint256 amountToTransfer = amount / numTokenHoldersInBatch;
        payable(msg.sender).transfer(amountToTransfer);
        batchInfo_[originalId].hasWithdrawnForIdAndEth[ethDepositId][msg.sender] = true;
    }

    /**
     * Withdraw all of the ERC20 for a specific deposit and receiver
     * @param   token The address of the ERC20 token to be deposited
     * @param   originalId ID of the parent token of a batch
     * @param   erc20DepositId The ID of the deposited ERC20 tokens (first deposit will have ID of zero, second ID of 1 and so on)
     */
    function withdrawERC20(IERC20 token, uint256 originalId, uint256 erc20DepositId) external {
        require(batchInfo_[originalId].isTokenHolder[msg.sender] == true, "Not a batch token holder");
        require(batchInfo_[originalId].hasWithdrawnForIdAndERC20[erc20DepositId][msg.sender] == false, "You have already withdrawn ERC20 tokens");
        uint256 numTokenHoldersInBatch = batchInfo_[originalId].tokenHolders.length;
        uint256 amount = batchInfo_[originalId].erc20DepositBalance[originalId][erc20DepositId];
        uint256 amountToTransfer = amount / numTokenHoldersInBatch;
        token.transfer(msg.sender, amountToTransfer);
        batchInfo_[originalId].hasWithdrawnForIdAndERC20[erc20DepositId][msg.sender] = true;
    }

    /**
     * Transfer function, which overrides the original ERC721 function
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        uint originalId = originalTokenId(tokenId);
        batchInfo_[originalId].isTokenHolder[from] = false;
        batchInfo_[originalId].isTokenHolder[to] = true;
        _removeTokenHolderFromBatch(from, tokenId);
        _addTokenHolderToExistingBatch(to, originalId);
        _transfer(from, to, tokenId);
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

        batchInfo_[_nextMintId].amountOfBatch = amountOfBatch;
        batchInfo_[_nextMintId].amountMinted = 1;
        batchInfo_[_nextMintId].lastMintedId = _nextMintId;
        batchInfo_[_nextMintId].batchURI = batchURI;
        originalTokenId_[_nextMintId] = _nextMintId;

        emit Batch(receiver, _nextMintId, amountOfBatch);

        batchInfo_[_nextMintId].isTokenHolder[receiver] = true;
        _addTokenHolderToNewBatch(receiver);
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
        originalTokenId_[_nextMintId] = originalId;

        if(batchInfo_[originalId].isTokenHolder[receiver] == false) {
            batchInfo_[originalId].isTokenHolder[receiver] = true;
            _addTokenHolderToExistingBatch(receiver, originalId);
        }

        _mint(receiver, _nextMintId);
        _nextMintId++;
        return (_nextMintId - 1);
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
        address tokenHolder = ownerOf(_tokenId);
        _removeTokenHolderFromBatch(tokenHolder, _tokenId);
        batchInfo_[originalTokenId(_tokenId)].isTokenHolder[tokenHolder] = false;

        require(approveBurn_[_tokenId], "Token not approved by owner");
        _burn(_tokenId);
    }
    // mainnet bridge?
}

