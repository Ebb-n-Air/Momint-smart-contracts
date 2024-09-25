import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
module {
  /*************************
    * Common Types
  *************************/
    public type AirdropValueType = {
        dividentAmount : Nat;
        token : TokenType;
    };

    public type Beneficaries = {
        #detectOnChain;
        #input : [Principal];
    };

    public type TokenType = {
        #ckUSDC;
        #ckUSDT;
        #ckETH;
        #ckBTC;
    };

    public type Airdrop = {
      id: Nat64;
        beneficiaries : [Principal];
        token : TokenType;
        dividentAmount : Nat;
        status : AirdropStatus;
        timestamp : Time.Time;
    };

    type AirdropStatus = {
        #pending;
        #completed;
        #failed;
    };

   public type InternalTransaction = {
        id : Nat64;
        from : Principal;
        to : Principal;
        txnId : Nat;
        amount : Nat;
        token : TokenType;
        timestamp : Time.Time;
    };


  /*************************    
    * dip721_replica Interface
  *************************/
    public type ApiError = {
    #ZeroAddress;
    #InvalidTokenId;
    #Unauthorized;
    #Other;
  };
  public type Dip721NonFungibleToken = {
    maxLimit : Nat16;
    logo : LogoResult;
    name : Text;
    symbol : Text;
  };
  public type ExtendedMetadataResult = {
    #Ok : { token_id : TokenId; metadata_desc : MetadataDesc };
    #Err : ApiError;
  };
  public type InterfaceId = {
    #Burn;
    #Mint;
    #Approval;
    #TransactionHistory;
    #TransferNotification;
  };
  public type LogoResult = { data : Text; logo_type : Text };
  public type MetadataDesc = [MetadataPart];
  public type MetadataKeyVal = { key : Text; val : MetadataVal };
  public type MetadataPart = {
    data : Blob;
    key_val_data : [MetadataKeyVal];
    purpose : MetadataPurpose;
  };
  public type MetadataPurpose = { #Preview; #Rendered };
  public type MetadataResult = { #Ok : MetadataDesc; #Err : ApiError };
  public type MetadataVal = {
    #Nat64Content : Nat64;
    #Nat32Content : Nat32;
    #Nat8Content : Nat8;
    #NatContent : Nat;
    #Nat16Content : Nat16;
    #BlobContent : Blob;
    #TextContent : Text;
  };
  public type MintReceipt = { #Ok : MintReceiptPart; #Err : ApiError };
  public type MintReceiptPart = { id : Nat; token_id : TokenId };
  public type OwnerResult = { #Ok : Principal; #Err : ApiError };
  public type TokenId = Nat64;
  public type TxReceipt = { #Ok : Nat; #Err : ApiError };
  public let ContractActor = actor "br5f7-7uaaa-aaaaa-qaaca-cai" : actor {
    balanceOfDip721 : shared query Principal -> async Nat64;
    getMaxLimitDip721 : shared query () -> async Nat16;
    getMetadataDip721 : shared query TokenId -> async MetadataResult;
    getMetadataForUserDip721 : shared Principal -> async ExtendedMetadataResult;
    getTokenIdsForUserDip721 : shared query Principal -> async [TokenId];
    ownerOfDip721 : shared query TokenId -> async OwnerResult;
    totalSupplyDip721 : shared query () -> async Nat64;
    getAllOwners: shared query () -> async [Principal] ;
  };

  /*************************
    * Token Interface
  *************************/

  public type Account = { owner : Principal; subaccount : ?Blob };
  public type MetadataValue = {
    #Int : Int;
    #Nat : Nat;
    #Blob : Blob;
    #Text : Text;
  };
  public type TransfereResult = { #Ok : Nat; #Err : TransferError }; 
  public type TransferArg = {
    to : Account;
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };
  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };

   public type TokenInterface = actor {
    icrc1_balance_of : shared query Account -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, MetadataValue)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_transfer : shared TransferArg -> async TransfereResult;
  }
};
