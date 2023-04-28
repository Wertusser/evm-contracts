import "forge-std/interfaces/IERC20.sol";

abstract contract WrapperExt {
  function previewWrap(address assetFrom, uint256 amount)
    public
    view
    virtual
    returns (uint256 wrappedAmount)
  {
    wrappedAmount = Wrapper__previewWrap(assetFrom, amount);
  }

  function previewUnwrap(address assetTo, uint256 wrappedAmount)
    public
    view
    virtual
    returns (uint256 amount)
  {
    amount = Wrapper__previewUnwrap(assetTo, wrappedAmount);
  }

  function wrap(address assetFrom, uint256 amount, address receiver)
    public
    virtual
    returns (uint256 wrappedAmount)
  {
    IERC20 wrappedAsset = IERC20(Wrapper__wrappedAsset());
    uint256 balanceBefore = wrappedAsset.balanceOf(address(this));

    IERC20(assetFrom).transferFrom(msg.sender, address(this), amount);
    Wrapper__wrap(assetFrom, amount);
    wrappedAmount = wrappedAsset.balanceOf(address(this)) - balanceBefore;

    wrappedAsset.transfer(receiver, wrappedAmount);
  }

  function unwrap(
    address assetTo,
    uint256 wrappedAmount,
    address receiver,
    address owner_
  ) public virtual returns (uint256 amount) {
    IERC20 wrappedAsset = IERC20(Wrapper__wrappedAsset());

    uint256 balanceBefore = IERC20(assetTo).balanceOf(address(this));

    wrappedAsset.transferFrom(owner_, address(this), wrappedAmount);
    Wrapper__unwrap(assetTo, wrappedAmount);
    amount = IERC20(assetTo).balanceOf(address(this)) - balanceBefore;

    IERC20(assetTo).transfer(receiver, amount);
  }

  function Wrapper__wrappedAsset() internal view virtual returns (address);
  function Wrapper__wrap(address assetFrom, uint256 amount) internal virtual;
  function Wrapper__unwrap(address assetTo, uint256 amount) internal virtual;

  function Wrapper__previewWrap(address assetFrom, uint256 amount)
    internal
    view
    virtual
    returns (uint256 wrappedAmount);
  function Wrapper__previewUnwrap(address assetTo, uint256 wrappedAmount)
    internal
    view
    virtual
    returns (uint256 amount);
}
