// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Timelock {

    address public immutable tokenContract; //ERC20 contract
    address public immutable beneficiary; //address to receive tokens after timelock
    uint256 public immutable releaseTime; //release time of lock

    constructor(address tokenContract_, address beneficiary_, uint256 lockDuration_) {
        require(lockDuration_ > 0, "lock duration must be greater than zero");

        tokenContract = tokenContract_;
        beneficiary = beneficiary_;
        releaseTime = block.timestamp + lockDuration_;
    }

    function release() public virtual {
        require(block.timestamp >= releaseTime, "current time is before release time");

        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "no tokens to release");

        IERC20(tokenContract).transfer(beneficiary, amount);
    }
}