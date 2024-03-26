// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract Guandan {
    uint256 private num;

    constructor(){
        num = 0;
    }

    function getNum() public returns(uint256) {
        num = 1;
        return num;
    }  

}