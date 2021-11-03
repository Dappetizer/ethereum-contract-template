// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Splitter is Ownable, PaymentSplitter {
    constructor(address[] memory payees_, uint256[] memory shares_) PaymentSplitter(payees_, shares_) {}
}