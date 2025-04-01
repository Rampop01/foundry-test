// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract W3XII {
    mapping(address => uint256) public balanceOf;
    bool public dosed;
    
    function deposit() external payable {
        require(msg.value == 0.5 ether, "InvalidAmount");
        require(balanceOf[msg.sender] < 1 ether, "Max deposit exceeded");
        require(address(this).balance < 2 ether, "deposit locked");
        
        balanceOf[msg.sender] += msg.value;
    }
    
    function withdraw() external {
        require(balanceOf[msg.sender] > 0, "No deposit");
        
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        
        if (address(this).balance >= 20 ether) {
            dosed = true;
        } else {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        }
    }
    
    function dest() external {
        require(dosed, "Not dosed");
        selfdestruct(payable(msg.sender));
    }
} 