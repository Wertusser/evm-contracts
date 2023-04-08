// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "./ERC4626.sol";

interface IFeeController {
  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount);
}

contract WithFees {
  IFeeController private controller;

  constructor(IFeeController feeController) {
    controller = feeController;
  }

  function feesController() public view returns (address) {
    return address(controller);
  }

  function payFees(uint256 amount, string memory feeType)
    public
    returns (uint256 feesAmount, uint256 restAmount)
  {
    return controller.collectFee(amount, feeType);
  }
}

contract FeesController is IFeeController, Ownable {
  uint24 constant MAX_BPS = 10000; // 100
  uint24 constant MAX_FEE_BPS = 2500; // 25%

  // vault address => amount
  mapping(address => uint256) public feesCollected;
  // vault address => treasury => amount
  mapping(address => mapping(address => uint256)) public feesCollectedByTreasuries;
  // vault address => type => bps
  mapping(address => mapping(string => uint24)) public feesConfig;
  // vault address => treasury address, if address(0) then use fallback treasury
  mapping(address => address) internal _treasuries;

  address public fallbackTreasury;

  event TreasuryUpdated(address nextTreasury);
  event FallbackTreasuryUpdated(address nextTreasury);
  event FeesUpdated(address indexed vault, string feeType, uint24 value);
  event FeesCollected(
    address indexed vault, string feeType, uint256 feeAmount, address asset
  );

  constructor(address fallbackTreasury_) Ownable() {
    fallbackTreasury = fallbackTreasury_;
  }

  function treasury(address vault) public view returns (address) {
    address result = _treasuries[vault];
    return result != address(0) ? result : fallbackTreasury;
  }

  function setFallbackTreasury(address nextTreasury) external onlyOwner {
    fallbackTreasury = nextTreasury;

    emit FallbackTreasuryUpdated(nextTreasury);
  }

  function setTreasury(address vault, address nextTreasury) external onlyOwner {
    _treasuries[vault] = nextTreasury;

    emit TreasuryUpdated(nextTreasury);
  }

  function setFee(address vault, string memory feeType, uint24 value) external onlyOwner {
    require(value <= MAX_FEE_BPS, "Fee overflow, max 25%");
    feesConfig[vault][feeType] = value;

    emit FeesUpdated(vault, feeType, value);
  }

  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount)
  {
    if (amount > 0 && feesConfig[msg.sender][feeType] > 0) {
      return _collectFee(msg.sender, amount, feeType);
    } else {
      return (0, amount);
    }
  }

  function _collectFee(address vault, uint256 amount, string memory feeType)
    internal
    returns (uint256 feesAmount, uint256 restAmount)
  {
    address asset = IERC4626(vault).asset();

    uint24 bps = feesConfig[vault][feeType];
    feesAmount = amount * bps / MAX_BPS;

    address treasury_ = treasury(vault);
    IERC20(asset).transferFrom(vault, treasury_, feesAmount);

    feesCollected[vault] += feesAmount;
    feesCollectedByTreasuries[vault][treasury_] += feesAmount;

    restAmount = amount - feesAmount;

    emit FeesCollected(vault, feeType, feesAmount, asset);
  }
}
