// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/// @custom:security-contact support@momint.so
contract MomintSimpleAirdrop is Initializable, PausableUpgradeable, OwnableUpgradeable {
    event BeneficiaryPaid(address indexed from, address indexed to, uint256 amount, string metadata);

    address public _usdcTokenAddress;

    struct PaymentData {
        address beneficiaryAddress;
        uint256 amount;
        string metadata;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address tokenAddress) {
        _disableInitializers();
        _usdcTokenAddress = tokenAddress;
    }

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function payBeneficiaries(PaymentData[] calldata payments) external {
        require(payments.length > 0, "No payments provided");

        for (uint256 i = 0; i < payments.length; i++) {
            address beneficiary = payments[i].beneficiaryAddress;
            uint256 amount = payments[i].amount;
            string calldata metadata = payments[i].metadata;

            require(beneficiary != address(0), "Invalid beneficiary address");

            payAddress(beneficiary, amount, metadata);
        }
    }

    function payAddress(address walletAddress, uint256 amount, string calldata metadata) internal {
        bool success = IERC20(_usdcTokenAddress).transferFrom(msg.sender, walletAddress, amount);
        require(success);
        emit BeneficiaryPaid(msg.sender, walletAddress, amount, metadata);
    }
}
