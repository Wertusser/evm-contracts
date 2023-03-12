// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "forge-std/interfaces/IERC20.sol";
import "./ERC4626.sol";
import "./Swapper.sol";

abstract contract ERC4626Controllable is ERC4626, AccessControl, Pausable {

    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    constructor(IERC20 asset_, address management, address emergency)
    ERC4626(asset_)
    Pausable()
    AccessControl() {
      _grantRole(MANAGEMENT_ROLE, management);
      _grantRole(EMERGENCY_ROLE, emergency);
    }

    function toggle() public onlyRole(EMERGENCY_ROLE) {
        if (paused()) _unpause();
        else _pause();
    }
}
