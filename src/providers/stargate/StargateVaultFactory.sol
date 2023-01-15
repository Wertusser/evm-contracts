// // SPDX-License-Identifier: AGPL-3.0
// pragma solidity ^0.8.13;

// import {ERC20} from 'solmate/tokens/ERC20.sol';
// import {ERC4626} from 'solmate/mixins/ERC4626.sol';

// import {IStargateRouter} from './external/IStargateRouter.sol';
// import {StargateVault} from './StargateVault.sol';
// import {ERC4626Factory} from '../../ERC4626Factory.sol';

// /// @title StargateVaultFactory
// /// @notice Factory for creating StargateVault contracts
// contract StargateVaultFactory is ERC4626Factory {
//     /// -----------------------------------------------------------------------
//     /// Errors
//     /// -----------------------------------------------------------------------

//     /// @notice Thrown when trying to deploy an StargateVault vault using an asset without an aToken
//     error StargateVaultFactory__ATokenNonexistent();

//     /// -----------------------------------------------------------------------
//     /// Immutable params
//     /// -----------------------------------------------------------------------

//     /// -----------------------------------------------------------------------
//     /// Constructor
//     /// -----------------------------------------------------------------------

//     constructor() {}

//     /// -----------------------------------------------------------------------
//     /// External functions
//     /// -----------------------------------------------------------------------

//     /// @inheritdoc ERC4626Factory
//     function createERC4626(ERC20 asset)
//         external
//         virtual
//         override
//         returns (ERC4626 vault)
//     {
//         IPool.ReserveData memory reserveData = lendingPool.getReserveData(
//             address(asset)
//         );
//         address aTokenAddress = reserveData.aTokenAddress;
//         if (aTokenAddress == address(0)) {
//             revert StargateVaultFactory__ATokenNonexistent();
//         }

//         vault = new StargateVault{salt: bytes32(0)}(
//             asset,
//             ERC20(aTokenAddress),
//             lendingPool,
//             rewardRecipient,
//             rewardsController
//         );

//         emit CreateERC4626(asset, vault);
//     }

//     /// @inheritdoc ERC4626Factory
//     function computeERC4626Address(ERC20 asset)
//         external
//         view
//         virtual
//         override
//         returns (ERC4626 vault)
//     {
//         IPool.ReserveData memory reserveData = lendingPool.getReserveData(
//             address(asset)
//         );
//         address aTokenAddress = reserveData.aTokenAddress;

//         vault = ERC4626(
//             _computeCreate2Address(
//                 keccak256(
//                     abi.encodePacked(
//                         // Deployment bytecode:
//                         type(StargateVault).creationCode,
//                         // Constructor arguments:
//                         abi.encode(
//                             asset,
//                             ERC20(aTokenAddress),
//                             lendingPool,
//                             rewardRecipient,
//                             rewardsController
//                         )
//                     )
//                 )
//             )
//         );
//     }
// }
