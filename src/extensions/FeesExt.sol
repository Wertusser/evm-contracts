import "../periphery/FeesController.sol";

contract FeesExt {
  IFeesController private controller;
    
    event FeesControllerUpdated(IFeesController newFeesController);

  constructor(IFeesController feeController) {
    controller = feeController;
  }

  function _setFeesController(IFeesController controller_) internal {
    controller = controller_;

    emit FeesControllerUpdated(controller);
  }

  function feesController() public view returns (address) {
    return address(controller);
  }

  function feeBps(string memory feeType) public view returns (uint24) {
    return controller.getFeeBps(address(this), feeType);
  }

  function acumulatedFeesByType(string memory feeType)
    public
    view
    returns (uint256 feesCollected)
  {
    return controller.feesCollected(address(this), feeType);
  }

  function payFees(uint256 amount, string memory feeType)
    public
    returns (uint256 feesAmount, uint256 restAmount)
  {
    return controller.collectFee(amount, feeType);
  }
}
