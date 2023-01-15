pragma solidity ^0.8.13;

import {Owned} from 'solmate/auth/Owned.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

struct Fees {
    address want;
    uint256 feeBps;
    bool useGlobal;
}

contract FeeController is Owned {
    uint256 constant MAX_BPS = 10_000;

    uint256 public globalFeeBps = 2_000;
    address public receiver;

    // total fees paid by vault (in want decimals)
    mapping(address => uint256) public feesPaid;

    // custom fee settings
    mapping(address => Fees) public settings;

    constructor(address owner, address receiver_) Owned(owner) {
        receiver = receiver_;
    }

    function create(ERC20 want) external {
        require(address(want) != address(0), 'want asset have zero address');
        require(
            settings[msg.sender].want == address(0),
            'Fee settings already exists for sender'
        );

        settings[msg.sender] = Fees(address(want), globalFeeBps, true);
    }

    function getFee(address vault, uint256 amountFrom)
        public
        view
        returns (uint256 feeAmount, address want)
    {
        Fees memory params = settings[vault];
        require(params.want != address(0), 'Fee settings doesnt exists');

        uint256 feeBps = params.useGlobal ? globalFeeBps : params.feeBps;

        want = params.want;
        feeAmount = (amountFrom * feeBps) / MAX_BPS;
    }

    function payFee(uint256 amountFrom) public returns (uint256) {
        (uint256 feesAmount, address want) = getFee(msg.sender, amountFrom);
        if (feesAmount > 0) {
            TransferHelper.safeTransferFrom(
                want,
                msg.sender,
                receiver,
                feesAmount
            );

            feesPaid[msg.sender] += feesAmount;
        }
        return feesAmount;
    }

    function setGlobalFeeBps(uint256 feeBps) external onlyOwner {
        require(feeBps < MAX_BPS, 'Invalid fee bps');

        globalFeeBps = feeBps;
    }

    function setReceiver(address receiver_) external onlyOwner {
        require(receiver_ != address(0));

        receiver = receiver_;
    }

    function setFee(
        address vault,
        uint256 feeBps,
        bool useGlobal
    ) external onlyOwner {
        require(feeBps < MAX_BPS, 'Invalid fee bps');
        Fees storage params = settings[vault];
        require(params.want != address(0), 'Fee settings doesnt exists');

        params.feeBps = feeBps;
        params.useGlobal = useGlobal;
    }
}
