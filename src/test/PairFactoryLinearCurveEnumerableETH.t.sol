// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {PairFactoryBase} from "./base/PairFactoryBase.sol";
import {UsingLinearCurve} from "./mixins/UsingLinearCurve.sol";
import {UsingEnumerable} from "./mixins/UsingEnumerable.sol";
import {UsingETH} from "./mixins/UsingETH.sol";

contract PairFactoryLinearCurveEnumerableETHTest is
    PairFactoryBase,
    UsingLinearCurve,
    UsingEnumerable,
    UsingETH
{}