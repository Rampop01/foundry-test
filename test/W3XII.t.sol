// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "forge-std/Test.sol";
import "../src/W3XII.sol";

contract W3CXIITest is Test {
    W3XII public w3cxii;
    address user = address(0x1);

    function setUp() public {
        w3cxii = new W3XII();
        vm.deal(user, 25 ether);
    }

    function testDeposit() public {
        vm.prank(user);
        w3cxii.deposit{value: 0.5 ether}();
        assertEq(w3cxii.balanceOf(user), 0.5 ether);
        assertEq(address(w3cxii).balance, 0.5 ether);
    }
    
    function testDepositInvalidAmount() public {
        vm.prank(user);
        vm.expectRevert("InvalidAmount");
        w3cxii.deposit{value: 0.1 ether}();
        
        vm.prank(user);
        vm.expectRevert("InvalidAmount");
        w3cxii.deposit{value: 1 ether}();
    }
    
    function testDepositMaxExceeded() public {
        vm.startPrank(user);
        w3cxii.deposit{value: 0.5 ether}();
        w3cxii.deposit{value: 0.5 ether}();
        vm.expectRevert("Max deposit exceeded");
        w3cxii.deposit{value: 0.5 ether}();
        vm.stopPrank();
    }
    
    function testDepositLocked() public {
        vm.startPrank(user);
        w3cxii.deposit{value: 0.5 ether}(); // Balance = 0.5 ether
        // Use deposit to reach 2 ether to avoid transfer quirks
        vm.prank(address(0x2)); // Different user
        vm.deal(address(0x2), 1.5 ether);
        w3cxii.deposit{value: 0.5 ether}(); // Total = 1 ether
        w3cxii.deposit{value: 0.5 ether}(); // Total = 1.5 ether
        w3cxii.deposit{value: 0.5 ether}(); // Total = 2 ether
        vm.prank(user);
        vm.expectRevert("deposit locked");
        w3cxii.deposit{value: 0.5 ether}();
        vm.stopPrank();
    }
    
    function testWithdraw() public {
        vm.prank(user);
        w3cxii.deposit{value: 0.5 ether}();
        uint256 balanceBefore = user.balance;
        vm.prank(user);
        w3cxii.withdraw();
        assertEq(user.balance, balanceBefore + 0.5 ether);
        assertEq(w3cxii.balanceOf(user), 0);
        assertEq(address(w3cxii).balance, 0);
    }
    
    function testWithdrawNoDeposit() public {
        vm.prank(user);
        vm.expectRevert("No deposit");
        w3cxii.withdraw();
    }
    
    function testDosed() public {
        vm.startPrank(user);
        w3cxii.deposit{value: 0.5 ether}();
        payable(address(w3cxii)).transfer(19.5 ether); // Total = 20 ether
        w3cxii.withdraw();
        assertTrue(w3cxii.dosed());
        assertEq(w3cxii.balanceOf(user), 0);
        assertEq(address(w3cxii).balance, 20 ether);
        vm.stopPrank();
    }
    
    function testDestruction() public {
        vm.startPrank(user);
        w3cxii.deposit{value: 0.5 ether}();
        payable(address(w3cxii)).transfer(19.5 ether); // Total = 20 ether
        w3cxii.withdraw();
        assertTrue(w3cxii.dosed());
        uint256 balanceBefore = user.balance;
        uint256 contractBalance = address(w3cxii).balance;
        w3cxii.dest();
        assertEq(user.balance, balanceBefore + contractBalance);
        vm.stopPrank();
    }
    
    function testDestNotDosed() public {
        vm.prank(user);
        vm.expectRevert("Not dosed");
        w3cxii.dest();
    }
}