// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

interface IFeesController {
  event TreasuryUpdated(address nextTreasury);
  event FallbackTreasuryUpdated(address nextTreasury);
  event FeesUpdated(address indexed vault, string feeType, uint24 value);
  event FeesCollected(
    address indexed vault, string feeType, uint256 feeAmount, address asset
  );

  function getFeeBps(address vault, string memory feeType)
    external
    view
    returns (uint24 feeBps);

  function setFeeBps(address vault, string memory feeType, uint24 value) external;

  function previewFee(uint256 amount, string memory feeType)
    external
    view
    returns (uint256 feesAmount, uint256 restAmount);

  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount);
}

contract WithFees {
  IFeesController private controller;

  constructor(IFeesController feeController) {
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

contract FeesController is IFeesController, Owned {
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

  constructor(address fallbackTreasury_) Owned(msg.sender) {
    fallbackTreasury = fallbackTreasury_;
  }

  function treasury(address vault) public view returns (address) {
    address result = _treasuries[vault];
    return result != address(0) ? result : fallbackTreasury;
  }

  function getFeeBps(address vault, string memory feeType)
    public
    view
    returns (uint24 feeBps)
  {
    return feesConfig[vault][feeType];
  }

  function setFallbackTreasury(address nextTreasury) external onlyOwner {
    fallbackTreasury = nextTreasury;

    emit FallbackTreasuryUpdated(nextTreasury);
  }

  function setTreasury(address vault, address nextTreasury) external onlyOwner {
    _treasuries[vault] = nextTreasury;

    emit TreasuryUpdated(nextTreasury);
  }

  function setFeeBps(address vault, string memory feeType, uint24 value)
    external
    onlyOwner
  {
    require(value <= MAX_FEE_BPS, "Fee overflow, max 25%");
    feesConfig[vault][feeType] = value;

    emit FeesUpdated(vault, feeType, value);
  }

  function previewFee(uint256 amount, string memory feeType)
    public
    view
    returns (uint256 feesAmount, uint256 restAmount)
  {
    uint24 bps = feesConfig[msg.sender][feeType];
    if (amount > 0 && bps > 0) {
      feesAmount = amount * bps / MAX_BPS;
      return (feesAmount, amount - feesAmount);
    } else {
      return (0, amount);
    }
  }

  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount)
  {
    return _collectFee(msg.sender, amount, feeType);
  }

  function _collectFee(address vault, uint256 amount, string memory feeType)
    internal
    returns (uint256 feesAmount, uint256 restAmount)
  {
    (feesAmount, restAmount) = previewFee(amount, feeType);
    if (feesAmount == 0) {
      return (feesAmount, restAmount);
    }

    address asset = IERC4626(vault).asset();

    address treasury_ = treasury(vault);
    IERC20(asset).transferFrom(vault, treasury_, feesAmount);

    feesCollected[vault] += feesAmount;
    feesCollectedByTreasuries[vault][treasury_] += feesAmount;

    emit FeesCollected(vault, feeType, feesAmount, asset);
  }
}
