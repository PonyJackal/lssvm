// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {LSSVMPairFactoryLike} from "../LSSVMPairFactoryLike.sol";

library LSSVMPairCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function clone(
        address implementation,
        LSSVMPairFactoryLike factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (11 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 0a
            // runtime size = 73
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 60 runtime  | PUSH1 runtime     (r) | r 0                     | –
            // 80          | DUP1                  | r r 0                   | –
            // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
            // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
            // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
            // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
            // f3          | RETURN                | 0                       | [0-2d]: runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (54 bytes of code + 61 bytes of extra data = 115 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 3d
            // 36          | CALLDATASIZE          | cds                     | –
            // 3d          | RETURNDATASIZE        | 0 cds                   | –
            // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
            // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
            // 60 extra    | PUSH1 extra           | extra                   | [0, cds] = calldata
            // 60 0x36     | PUSH1 0x36            | 0x36 extra              | [0, cds] = calldata // 0x36 (54) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x36 extra          | [0, cds] = calldata
            // 39          | CODECOPY              | _                       | [0, cds] = calldata
            // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
            // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
            // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
            // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0         | [0, cds] = calldata
            // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
            mstore(
                ptr,
                hex"3d_60_73_80_60_0a_3d_39_81_f3_36_3d_3d_37_60_3d_60_36_36_39_3d_3d_3d_36_60_3d_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
            // f4          | DELEGATECALL          | success 0                | [0, cds] = calldata
            // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
            // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
            // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
            // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
            // 90          | SWAP1                 | 0 success               | [0, rds] = return data
            // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
            // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
            // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
            // fd          | REVERT                | –                       | [0, rds] = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
            // f3          | RETURN                | –                       | [0, rds] = return data
            mstore(
                add(ptr, 0x31),
                0x5af43d82803e903d91603457fd5bf30000000000000000000000000000000000
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (61 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x40), shl(0x60, factory))
            mstore(add(ptr, 0x54), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x68), shl(0x60, nft))
            mstore8(add(ptr, 0x7c), poolType)

            instance := create(0, ptr, 0x7d)
        }
    }

    function isClone(address implementation, address query)
        internal
        view
        returns (bool result)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"36_3d_3d_37_60_73_60_36_36_39_3d_3d_3d_36_60_73_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(
                add(ptr, 0x27),
                0x5af43d82803e903d91603457fd5bf30000000000000000000000000000000000
            )

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x40)
            extcodecopy(query, other, 0, 0x36)
            result := and(
                eq(mload(ptr), mload(other)),
                eq(mload(add(ptr, 0x16)), mload(add(other, 0x16)))
            )
        }
    }
}