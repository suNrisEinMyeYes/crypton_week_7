// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface Itoken is IERC20 {

    function updateAdmin(address newAdmin) external;

    function mint(address to, uint amount) external;

    function burn(address owner, uint amount) external;

    function getAdmin() external view returns(address);

}