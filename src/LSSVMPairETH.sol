// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {LSSVMPairFactoryLike} from "./LSSVMPairFactoryLike.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

abstract contract LSSVMPairETH is LSSVMPair {
    using Address for address payable;

    // Only called once by factory to initialize
    function initialize(
        IERC721 _nft,
        ICurve _bondingCurve,
        LSSVMPairFactoryLike _factory,
        PoolType _poolType,
        uint256 _delta,
        uint256 _fee,
        uint256 _spotPrice
    ) external payable initializer {
        __LSSVMPair_init(
            _nft,
            _bondingCurve,
            _factory,
            _poolType,
            _delta,
            _fee,
            _spotPrice
        );
    }

    function isETHPair() external pure override returns (bool) {
        return true;
    }

    function _validateTokenInput(uint256 inputAmount) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");
    }

    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).sendValue(msg.value - inputAmount);
        }
    }

    function _payProtocolFee(LSSVMPairFactoryLike _factory, uint256 protocolFee)
        internal
        override
    {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the above calculations
            uint256 pairETHBalance = address(this).balance;
            if (protocolFee > pairETHBalance) {
                protocolFee = pairETHBalance;
            }
            _factory.protocolFeeRecipient().sendValue(protocolFee);
        }
    }

    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send ETH to caller
        if (outputAmount > 0) {
            tokenRecipient.sendValue(outputAmount);
        }
    }

    /**
        @notice Withdraws all token owned by the pair to the owner address.
        Only callable by the owner.
     */
    function withdrawAllETH() external onlyOwner onlyUnlocked nonReentrant {
        withdrawETH(address(this).balance);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pair to the owner address.
        Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) public onlyOwner onlyUnlocked {
        payable(owner()).sendValue(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawn(amount);
    }

    /**
        @notice Withdraws ERC20 tokens from the pair to the owner. Only callable by the owner.
        @param a The address of the token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(address a, uint256 amount)
        external
        override
        onlyOwner
        onlyUnlocked
    {
        IERC20(a).transferFrom(address(this), msg.sender, amount);
    }

    /**
        @dev All token transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposited(msg.value);
    }
}