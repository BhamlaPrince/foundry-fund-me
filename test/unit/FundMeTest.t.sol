// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    DeployFundMe deploy;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        deploy = new DeployFundMe();
        fundme = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarUsd() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerismsgsender() public view {
        // assertEq(fundme.i_owner(), msg.sender);
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testfundmefailswithoutenougheth() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundmeUpdatesFundmeDataStructures() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        uint256 amount = fundme.getaddresstofund(USER);
        assertEq(amount, SEND_VALUE);
    }

    function testAddsFunderToArrayofFunder() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        address funder = fundme.getfunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdrawFunds() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawASingleFunder() public {
        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundedBalance = address(fundme).balance;
        // Act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundedBalance = address(fundme).balance;

        assertEq(endingFundedBalance, 0);

        assertEq(
            startingFundedBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberofFundrs = 10;
        uint160 startingfunderIndex = 1;
        for (uint160 i = startingfunderIndex; i < numberofFundrs; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundedBalance = address(fundme).balance;
        // Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();
        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundedBalance = address(fundme).balance;

        assertEq(endingFundedBalance, 0);

        assertEq(
            startingFundedBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
