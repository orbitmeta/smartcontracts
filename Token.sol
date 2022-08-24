// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract Token is ERC1363, Pausable, AccessControl {
    uint256 public constant cap = 2_000_000_000 * 1e18;

    bool private isTransferable;
    bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");

    event IsTransferable(address account);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        isTransferable = false;

        _mint(msg.sender, cap);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function enableTransfer() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isTransferable = true;

        emit IsTransferable(msg.sender);
    }

    function addToBlacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(BLACKLISTED_ROLE, account);
    }

    function removeFromBlacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(BLACKLISTED_ROLE, account);
    }

    function isBlacklisted(address account) public view returns(bool) {
        return hasRole(BLACKLISTED_ROLE, account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!(hasRole(BLACKLISTED_ROLE, from)), "Token: address blocked");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (hasRole(DEFAULT_ADMIN_ROLE, from)) {
            super._transfer(from, to, amount);
            return;
        }

        require(isTransferable, "Token: cannot yet transferring");
        super._transfer(from, to, amount);
    }

    function burn(address account, uint256 amount) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(account, amount);
    }



    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1363, AccessControl)
    returns (bool)
    {
        return
        interfaceId == type(IERC1363).interfaceId ||
        interfaceId == type(IAccessControl).interfaceId ||
        interfaceId == type(IERC165).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}
