import Types "types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import List "mo:base/List";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

shared actor class AIRDROP() = this {
    type TokenLedgersInterface = Types.TokenInterface;
    type TokenType = Types.TokenType;
    type AirdropValueType = Types.AirdropValueType;
    type Beneficaries = Types.Beneficaries;
    type Airdrop = Types.Airdrop;
    type InternalTransaction = Types.InternalTransaction;

    stable var airdrops = List.nil<Airdrop>();
    stable var internalTransactions = List.nil<InternalTransaction>();

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
    public shared ({ caller }) func payBeneficiaries(payments : Beneficaries, token : TokenType) : async Result.Result<(), Text> {
        assert (Principal.isController(caller));
        if (token != airdropAmount.token) {
            return #err("Airdrop token should be set first.");
        };
        if (airdropAmount.amount == 0) {
            return #err("Airdrop amount should be set first.");
        };

        let users = switch (payments) {
            case (#input(ids)) { ids };
            case (#detectOnChain) {
                let _ids = await SharesContract.getAllOwners();
                let idsBuffer = Buffer.fromArray<Principal>(_ids);
                Buffer.removeDuplicates<Principal>(idsBuffer, Principal.compare);
                Buffer.toArray<Principal>(idsBuffer);
            };
        };
        let airdrop : Airdrop = {
            id = Nat64.fromNat(List.size(airdrops));
            beneficiaries = users;
            token = token;
            amount = airdropAmount.amount;
            status = #pending;
            timestamp = Time.now();
        };
        airdrops := List.push(airdrop, airdrops);
        for (beneficiary in users.vals()) {
            let result = await transfereTokens(beneficiary, token);
            switch (result) {
                case (#ok()) {
                    let transaction : InternalTransaction = {
                        id = Nat64.fromNat(List.size(internalTransactions));
                        from = Principal.fromActor(this);
                        to = beneficiary;
                        amount = airdropAmount.amount;
                        token = token;
                        timestamp = Time.now();
                    };
                    internalTransactions := List.push(transaction, internalTransactions);
                };
                case (#err(err)) {
                    func updateDrop(drop : Airdrop) : Airdrop {
                        if (drop.id == airdrop.id) {
                            return {
                                airdrop with
                                status = #failed;
                            };
                        } else {
                            return drop;
                        };
                    };
                    airdrops := List.map(airdrops, updateDrop);
                    return #err(err);
                };
            };
        };
        func updateDrop(drop : Airdrop) : Airdrop {
            if (drop.id == airdrop.id) {
                return {
                    airdrop with
                    status = #completed;
                };
            } else {
                return drop;
            };
        };
        airdrops := List.map(airdrops, updateDrop);
        airdropAmount := { amount = 0; token = token };
        return #ok;
    };

    public shared query func getAirdrops() : async [Airdrop] {
        return List.toArray(airdrops);
    };

    public shared query func getInternalTransactions() : async [InternalTransaction] {
        return List.toArray(internalTransactions);
    };

    public shared ({ caller }) func setAirdropAmount(args : AirdropValueType) : async () {
        assert (Principal.isController(caller));
        airdropAmount := args;
    };

    public shared query func getAirdropAmount() : async AirdropValueType {
        return airdropAmount;
    };

    private func transfereTokens(beneficiary : Principal, token : TokenType) : async Result.Result<(), Text> {
        let tokenInfo = switch (token) {
            case (#ckUSDC) { ckUSDCLedgerAddress };
            case (#ckUSDT) { ckUSDTLedgerAddress };
            case (#ckETH) { ckETHLedgerAddress };
            case (#ckBTC) { ckBTCLedgerAddress };
        };

        let ledger = actor (tokenInfo.address) : TokenLedgersInterface;

        let transferArg : Types.TransferArg = {
            to = { owner = beneficiary; subaccount = null };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = airdropAmount.amount * tokenInfo.decimals;
        };

        switch (await ledger.icrc1_transfer(transferArg)) {
            case (#Err(error)) {
                return #err(handleTransferError(error));
            };
            case (#Ok(_)) {
                return #ok();
            };
        };
    };

    func handleTransferError(err : Types.TransferError) : Text {
        return switch (err) {
            case (#GenericError(details)) {
                "Generic error: " # details.message # " (code: " # Nat.toText(details.error_code) # ")";
            };
            case (#TemporarilyUnavailable) {
                "Temporarily unavailable";
            };
            case (#BadBurn(details)) {
                "Bad burn, minimum amount: " # Nat.toText(details.min_burn_amount);
            };
            case (#Duplicate(details)) {
                "Duplicate transaction, original ID: " # Nat.toText(details.duplicate_of);
            };
            case (#BadFee(details)) {
                "Incorrect fee, expected: " # Nat.toText(details.expected_fee);
            };
            case (#CreatedInFuture(details)) {
                "Created in the future, ledger time: " # Nat64.toText(details.ledger_time);
            };
            case (#TooOld) {
                "Transaction too old";
            };
            case (#InsufficientFunds(details)) {
                "Insufficient funds, balance: " # Nat.toText(details.balance);
            };
        };
    };
};
