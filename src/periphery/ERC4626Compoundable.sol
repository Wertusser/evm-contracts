import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/interfaces/IERC20.sol";
import "./ERC4626.sol";
import "./Swapper.sol";

abstract contract ERC4626Compoundable is ERC4626, Ownable {
    /// @notice The expected reward token from integrated provider
    IERC20 public reward;
    /// @notice Swapper contract
    ISwapper public swapper;
    /// @notice someone who can harvest/tend in that vault
    address public keeper;

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Only keeper can call that function");
        _;
    }

    constructor(IERC20 asset_, IERC20 reward_, ISwapper swapper_, address keeper_)
    ERC4626(asset_)
    Ownable() {
      reward = reward_;
      keeper = keeper_;
      swapper = swapper_;
    }

    event Harvest(address indexed executor, uint256 amountReward, uint256 amountWant);
    event Tend(address indexed executor, uint256 amountWant, uint256 amountShares);
    event KeeperUpdated(address newKeeper);
    event SwapperUpdated(address newSwapper);

    function setKeeper(address nextKeeper) public onlyOwner {
        require(nextKeeper != address(0), "Zero address");
        keeper = nextKeeper;
        emit KeeperUpdated(keeper);
    }


    function setSwapper(ISwapper nextSwapper) public onlyOwner {
        uint256 expectedSwap = nextSwapper.previewSwap(reward, want, 10 ** reward.decimals());
        require(expectedSwap > 0, "This swapper doesn't supports swaps");
        swapper = nextSwapper;
        emit SwapperUpdated(address(swapper));
    }

    function harvest() public onlyKeeper returns (uint256 wantAmount) {
        (uint256 rewardAmount, uint256 wantAmount_ ) = _harvest();
        wantAmount = wantAmount_;
        emit Harvest(msg.sender, rewardAmount, wantAmount);
    }

    function tend() public onlyKeeper returns (uint256 sharesAdded) {
        (uint256 wantAmount, uint256 sharesAdded_ ) = _tend();
        sharesAdded = sharesAdded_;
        emit Tend(msg.sender, wantAmount, sharesAdded);
    }

    function previewHarvest() public virtual view returns (uint256);
    function previewTend() public virtual view returns (uint256);
    function _harvest() internal virtual returns (uint256 rewardAmount, uint256 wantAmount);
    function _tend() internal virtual returns (uint256 wantAmount, uint256 sharesAdded);
}
