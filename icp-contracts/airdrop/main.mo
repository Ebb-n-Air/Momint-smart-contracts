import Types "types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
actor {
    //TODO:
    // Transfer tokens to beneficiaries
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
                return #ok();
            };
            case (#ckUSDT) {
                return #ok();
            };
            case (#ckETH) {
                return #ok();
            };
            case (#ckBTC) {
                return #ok();
            };
        };
    };
};
