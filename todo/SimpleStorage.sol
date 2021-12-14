// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint x;

    function set(uint newValue) public {
        x = newValue;
    }
    
    function get() public view returns (uint) {
        return x;
    }
}