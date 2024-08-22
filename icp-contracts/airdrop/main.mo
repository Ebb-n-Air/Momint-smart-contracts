import Types "types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";

actor {
    //TODO:
    // Transfer tokens to beneficiaries

    func transferTokens(beneficiary : Principal, token : TokenType) : async Result.Result<(), Text> {
        // Define the ledger address based on the token type
        let ledgerAddress = switch (token) {
            case (#ckUSDC) ckUSDCLedgerAddress.address;
            case (#ckUSDT) ckUSDTLedgerAddress.address;
            case (#ckETH) ckETHLedgerAddress.address;
            case (#ckBTC) ckBTCLedgerAddress.address;
        };
        
        let ledger = actor(ledgerAddress) : TokenLedgersInterface;
        
        // Create the transfer argument
        let transferArg = {
            to = { owner = beneficiary; subaccount = null };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = airdropAmount.amount;
        };
        
        // Perform the transfer
        let transferResult = await ledger.icrc1_transfer(transferArg);
        
        // Handle the result of the transfer
        switch (transferResult) {
            case (#Ok(_)) {
                return #ok();
            };
            case (#Err(err)) {
                let errorMsg = switch (err) {
                    case (#GenericError(details)) {
                        "Generic error: " # details.message # " (code: " # Nat.toText(details.error_code) # ")"
                    };
                    case (#TemporarilyUnavailable) {
                        "Temporarily unavailable"
                    };
                    case (#BadBurn(details)) {
                        "Bad burn, minimum amount: " # Nat.toText(details.min_burn_amount)
                    };
                    case (#Duplicate(details)) {
                        "Duplicate transaction, original ID: " # Nat.toText(details.duplicate_of)
                    };
                    case (#BadFee(details)) {
                        "Incorrect fee, expected: " # Nat.toText(details.expected_fee)
                    };
                    case (#CreatedInFuture(details)) {
                        "Created in the future, ledger time: " # Nat64.toText(details.ledger_time)
                    };
                    case (#TooOld) {
                        "Transaction too old"
                    };
                    case (#InsufficientFunds(details)) {
                        "Insufficient funds, balance: " # Nat.toText(details.balance)
                    };
                };
                return #err(errorMsg);
            };
        };
    };
    
    // Add history maps to store the airdrop history

    let ckUSDCLedgerAddress = {
        address = "xevnm-gaaaa-aaaar-qafnq-cai";
        decimals = 1_000_000;
    };
    let ckUSDTLedgerAddress = {
        address = "cngnf-vqaaa-aaaar-qag4q-cai";
        decimals = 1_000_000;
    };
    let ckETHLedgerAddress = {
        address = "ss2fx-dyaaa-aaaar-qacoq-cai";
        decimals = 1_000_000_000_000_000_000;
    };
    let ckBTCLedgerAddress = {
        address = "mxzaz-hqaaa-aaaar-qaada-cai";
        decimals = 100_000_000;
    };

    let SharesContract = Types.ContractActor;

    stable var airdropAmount : AirdropValueType = {
        amount = 0;
        token = #ckUSDC;
    };
    type AirdropValueType = {
        amount : Nat64;
        token : TokenType;
    };
    type TokenLedgersInterface = Types.TokenInterface;

    type Beneficaries = {
        #detectOnChain;
        #input : [Principal];
    };

    public type TokenType = {
        #ckUSDC;
        #ckUSDT;
        #ckETH;
        #ckBTC;
    };

    public shared ({ caller }) func payBeneficiaries(payments : Beneficaries, token : TokenType) : async Result.Result<(), Text> {
        assert (Principal.isController(caller));
        if (token != airdropAmount.token) {
            return #err("Airdrop token should be set first.");
        };
        if (airdropAmount.amount == 0) {
            return #err("Airdrop amount should be set first.");
        };
        switch (payments) {
            case (#input(ids)) {
                for (beneficiary in ids.vals()) {
                    let result = await transfereTokens(beneficiary, token);
                    switch (result) {
                        case (#ok()) {
                            //TODO: Add to history
                            // Add to history
                        };
                        case (#err(err)) {
                            //TODO: Handle error
                            return #err(err);
                        };
                    };
                };
            };
            case (#detectOnChain) {
                let beneficiaries = await SharesContract.getAllOwners();
                // TODO: Check for duplicates and filter out the duplicates
                for (beneficiary in beneficiaries.vals()) {
                    let result = await transfereTokens(beneficiary, token);
                    switch (result) {
                        case (#ok()) {};
                        case (#err(err)) {
                            return #err(err);
                        };
                    };
                };

            };
        };
        airdropAmount := { amount = 0; token = token };
        return #ok;
    };

    public shared ({ caller }) func setAirdropAmount(args : AirdropValueType) : async () {
        assert (Principal.isController(caller));
        airdropAmount := args;
    };

    public shared query func getAirdropAmount() : async AirdropValueType {
        return airdropAmount;
    };

    private func transfereTokens(beneficiary : Principal, token : TokenType) : async Result.Result<(), Text> {
        switch (token) {
            case (#ckUSDC) {
                // TODO: Transfer tokens
                return #ok();
            };
            case (#ckUSDT) {
                // TODO: Transfer tokens
                return #ok();
            };
            case (#ckETH) {
                // TODO: Transfer tokens
                return #ok();
            };
            case (#ckBTC) {
                // TODO: Transfer tokens
                return #ok();
            };
        };
    };
};
