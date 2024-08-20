import Types "types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
actor {

    //TODO: on transfer, use the decimals from the token contract
    // Check if the given token is the same as the airdrop token, if not, return an error explaining that the airdrop token should be set.
    // set decimals on the airdrop value for the token


    let ckUSDCLedgerAddress = "xevnm-gaaaa-aaaar-qafnq-cai";
    let ckUSDTLedgerAddress = "cngnf-vqaaa-aaaar-qag4q-cai";
    let ckETHLedgerAddress = "ss2fx-dyaaa-aaaar-qacoq-cai";
    let ckBTCLedgerAddress = "mxzaz-hqaaa-aaaar-qaada-cai";
    let SharesContract = Types.ContractActor;

    var airdropAmount  : AirdropValueType = {
        amount = 10000;
        token = #ckUSDC;
    };
    type AirdropValueType = {
        amount: Nat64;
        token: TokenType;
    };
    type TokenLedgersInterface = Types.TokenInterface;

    public type TokenType = {
        #ckUSDC;
        #ckUSDT;
        #ckETH;
        #ckBTC;
    };
    
    public shared ({caller}) func payBeneficiaries(payments: [Principal], token: TokenType) : async Result.Result<(), Text> {
        assert(Principal.isController(caller));
        for (beneficiary in payments.vals()) {
            let userTokenIds = await SharesContract.getTokenIdsForUserDip721(beneficiary);
        };
        return #ok
    };

    public shared ({caller}) func setAirdropAmount(args:  AirdropValueType ) : async () {
        assert(Principal.isController(caller));
        airdropAmount := args;
    }; 

    public shared query func getAirdropAmount() : async  AirdropValueType  {
        return airdropAmount;
    };

    // private func transfereTokens(beneficiary: Principal, token: TokenType) : async Result.Result<(), Text> {
    //     switch (token) {
    //         case (#ckUSDC) {
    //          
    //         };
    //         case (#ckUSDT) {
    //          
    //         };
    //         case (#ckETH) {

    //         };
    //         case (#ckBTC) {
    //
    //         };
    //     };
    // }; 
};