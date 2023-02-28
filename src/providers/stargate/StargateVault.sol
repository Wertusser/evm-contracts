// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

interface IStargateRouter {
    function addLiquidity(uint256 _from, uint256 _amountLD, address _to) external;

    function instantRedeemLocal(uint16 _from, uint256 _amountLP, address _to) external returns (uint256);
}

contract StargateVault is UUPSUpgradeable, ERC4626 {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The stargate bridge router contract
    IStargateRouter public immutable stargateRouter;
    /// @notice The stargate pool id
    uint256 public immutable poolId;
    /// @notice The stargate lp asset
    ERC20 public immutable lpToken;

    /// -----------------------------------------------------------------------
    /// Mutable params
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }

    function initialize(ERC20 asset_, ERC20 lpToken_, IStargateRouter router_, uint256 poolId_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_));
        stargateRouter = router_;
        lpToken = lpToken_;
        poolId = poolId_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // TODO: write migrateToNewImplementation
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Withdraw assets from Stargate
        /// -----------------------------------------------------------------------

        startgateRouter.instantRedeemLocal(address(this), assets, address(this));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Stargate
        /// -----------------------------------------------------------------------

        // approve asset to Stargate pool
        SafeTransferLib.safeApprove(asset.token(), address(this), assets);

        // mint Stargate pool LP tokens
        startgateRouter.addLiquidity(poolId, address(this), assets);
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(poolId);
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(poolId);
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// Internal stargate fuctions
    /// -----------------------------------------------------------------------

    function getPoolRate() internal view virtual returns (uint256 rate) {

    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC20 asset_) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("ERC4626-Wrapped Stargate ", asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("ysg", asset_.symbol());
    }
}
