// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "forge-std/interfaces/IERC20.sol";
import { ERC4626, IERC4626 } from "./ERC4626.sol";
import "./Swapper.sol";

abstract contract ERC4626Controllable is ERC4626, AccessControl {
  bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");
  bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
  bool public canDeposit;
  address public admin;

  mapping(address => uint256) public depositOf;
  mapping(address => uint256) public withdrawOf;

  constructor(IERC20 asset_, address admin_) ERC4626(asset_) AccessControl() {
    _setupRole(DEFAULT_ADMIN_ROLE, admin_);
    _setupRole(MANAGEMENT_ROLE, admin_);
    _setupRole(EMERGENCY_ROLE, admin_);

    canDeposit = true;
  }

  function toggle() public onlyRole(EMERGENCY_ROLE) {
    canDeposit = !canDeposit;
  }

  function setRole(bytes32 role, address account, bool remove) internal {
    if (remove) {
      revokeRole(role, account);
    } else {
      grantRole(role, account);
    }
  }

  function setManager(address manager, bool remove) public onlyRole(DEFAULT_ADMIN_ROLE) {
    setRole(MANAGEMENT_ROLE, manager, remove);
  }

  function setEmergency(address manager, bool remove) public onlyRole(DEFAULT_ADMIN_ROLE) {
    setRole(EMERGENCY_ROLE, manager, remove);
  }

  /////////////////

  function pnl(address user) public view returns (int256) {
    uint256 totalDeposited = depositOf[user];
    uint256 totalWithdraw = withdrawOf[user] + this.maxWithdraw(user);

    return int256(totalWithdraw) - int256(totalDeposited);
  }

  /**
   * @dev Deposit/mint common workflow.
   */
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    virtual
    override
  {
    require(canDeposit, "Error: deposits is currently paused");
    _asset.transferFrom(caller, address(this), assets);
    _mint(receiver, shares);

    depositOf[receiver] += assets;

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Withdraw/redeem common workflow.
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }

    _burn(owner, shares);
    _asset.transfer(receiver, assets);

    withdrawOf[receiver] += assets;

    emit Withdraw(caller, receiver, owner, assets, shares);
  }
}
