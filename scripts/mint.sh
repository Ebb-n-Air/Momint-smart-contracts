#!/bin/bash

# Define the array of principal IDs
principalIds=(
    "s5lbg-44xwv-glshm-kqyur-fhp7d-3xecn-c54jn-n5nfj-yvij6-vp4lc-2ae"
    "vzsxd-brkyp-jtiec-xrmgq-pr5y5-wj4xm-vqft6-qm2mv-wxz7l-y6s2g-iqe"
    "7g5cv-4dtfe-ttwij-nft3e-trx7x-3tebe-rhlg4-tqaou-jwh6m-l67oj-bae"
    "frttq-vvkit-apzml-22btp-j6y5f-6hkoo-ukdbt-yqdcr-xjonr-kkhpt-cae"
    "rv2xe-yfz6s-7wvig-tribe-3hdmx-6mkda-m65wo-khf2l-pvxgd-3ugsg-3ae"
)

# Loop over each principal ID and mint NFTs
for id in "${principalIds[@]}"; do
    echo "Minting for $id"

    # Use expect to run the dfx command
    expect <<EOF
    spawn dfx canister call erc721_replica mintDip721 "(principal \"$id\", vec { record { purpose = variant{Rendered}; data = blob\"hello\"; key_val_data = vec { record { key = \"description\"; val = variant{TextContent=\"The NFT metadata can hold arbitrary metadata\"}; }; record { key = \"tag\"; val = variant{TextContent=\"anime\"}; }; record { key = \"contentType\"; val = variant{TextContent=\"text/plain\"}; }; record { key = \"locationType\"; val = variant{Nat8Content=4:nat8}; }; } } })"
    expect eof
EOF

done