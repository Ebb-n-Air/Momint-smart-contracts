dfx deploy token --argument "(variant { Init =
record {
     token_symbol = \"ICRC1\";
     token_name = \"L-ICRC1\";
     minting_account = record { owner = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\" };
     transfer_fee = 10_000;
     metadata = vec {};
     initial_balances = vec { record { record { owner = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\"; }; 10_000_000_000_000_000; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\";
     };
 }
})"

dfx deploy erc721_replica --argument "(
  principal\"$(dfx identity get-principal)\", 
  record {
    logo = record {
      logo_type = \"image/png\";
      data = \"\";
    };
    name = \"My DIP721\";
    symbol = \"DFXB\";
    maxLimit = 20;
  }
)"

dfx canister call token icrc1_transfer "(record {
  to = record {
    owner = principal \"be2us-64aaa-aaaaa-qaabq-cai\";
  };
  amount = 1_000_000_000;
})"

dfx canister install token --mode reinstall --argument "(variant { Init =
record {
     token_symbol = \"ICRC1\";
     token_name = \"L-ICRC1\";
     minting_account = record { owner = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\" };
     transfer_fee = 10_000;
     metadata = vec {};
     initial_balances = vec { record { record { owner = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\"; }; 10_000_000_000_000_000; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"nu4ce-6r22f-2x4c3-byypo-ltk2h-rpoks-qd3hw-w22d6-n6adq-iwahh-jae\";
     };
 }
})"