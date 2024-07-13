// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

contract EncryptedERC20 is EIP712WithModifier {
    using TFHE for uint256;

    euint32 private totalSupply;
    string public constant name = "Confidential USD";
    string public constant symbol = "CUSD";
    uint8 public constant decimals = 18;

    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;

    // A mapping from address to an encrypted balance.
    mapping(address => euint32) internal balances;

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    mapping(address => mapping(address => euint32)) internal allowances;

    // The owner of the contract.
    address public contractOwner;

    constructor() EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;
    }

    uint32 public randomX;

    function getRandom() public {
        randomX = TFHE.decrypt(TFHE.randEuint32());
    }

    function popCount(euint32 x) internal pure returns (euint32 c) {
        //https://github.com/Vectorized/solady/blob/main/src/utils/LibBit.sol - inspired by

        euint32 max = TFHE.not(TFHE.asEuint32(0));
        ebool isMax = TFHE.eq(x, max);
        x = TFHE.sub(x, TFHE.and(TFHE.shr(x, 1), TFHE.div(max, 3)));
        x = TFHE.add(
            TFHE.and(x, TFHE.div(max, 5)),
            TFHE.and(TFHE.shr(x, 2), TFHE.div(max, 5))
        );
        x = TFHE.and(TFHE.add(x, TFHE.shr(x, 4)), TFHE.div(max, 17));
        c = TFHE.or(
            TFHE.shl(TFHE.asEuint32(isMax), 8),
            TFHE.shr(TFHE.mul(x, TFHE.div(max, 255)), 248)
        );
    }

    function popCountTest(uint256 a) public view returns (uint256) {
        euint32 test = a.asEuint32();
        return TFHE.decrypt(popCount(test));
    }

    function countTerritories(
        euint32[2] memory bitmap
    ) internal pure returns (euint32 c) {
        euint32 count1 = popCount(bitmap[0]);
        euint32 count2 = popCount(bitmap[1]);
        c = TFHE.add(count1, count2);
    }

    // Sets the balance of the owner to the given encrypted balance.
    function mint(bytes calldata encryptedAmount) public onlyContractOwner {
        euint32 amount = TFHE.asEuint32(encryptedAmount);
        balances[contractOwner] = balances[contractOwner] + amount;
        totalSupply = totalSupply + amount;
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, bytes calldata encryptedAmount) public {
        transfer(to, TFHE.asEuint32(encryptedAmount));
    }

    // Transfers an amount from the message sender address to the `to` address.
    function transfer(address to, euint32 amount) public {
        _transfer(msg.sender, to, amount);
    }

    function getTotalSupply(
        bytes32 publicKey,
        bytes calldata signature
    )
        public
        view
        onlySignedPublicKey(publicKey, signature)
        returns (bytes memory)
    {
        return TFHE.reencrypt(totalSupply, publicKey, 0);
    }

    // Returns the balance of the caller encrypted under the provided public key.
    function balanceOf(
        bytes32 publicKey,
        bytes calldata signature
    )
        public
        view
        onlySignedPublicKey(publicKey, signature)
        returns (bytes memory)
    {
        return TFHE.reencrypt(balances[msg.sender], publicKey, 0);
    }

    // Sets the `encryptedAmount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, bytes calldata encryptedAmount) public {
        address owner = msg.sender;
        _approve(owner, spender, TFHE.asEuint32(encryptedAmount));
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller. The returned ciphertext is under the caller public FHE key.
    function allowance(
        address spender,
        bytes32 publicKey,
        bytes calldata signature
    )
        public
        view
        onlySignedPublicKey(publicKey, signature)
        returns (bytes memory)
    {
        address owner = msg.sender;

        return TFHE.reencrypt(_allowance(owner, spender), publicKey);
    }

    // Transfers `encryptedAmount` tokens using the caller's allowance.
    function transferFrom(
        address from,
        address to,
        bytes calldata encryptedAmount
    ) public {
        transferFrom(from, to, TFHE.asEuint32(encryptedAmount));
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, euint32 amount) public {
        address spender = msg.sender;
        _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
    }

    function _approve(address owner, address spender, euint32 amount) internal {
        allowances[owner][spender] = amount;
    }

    function _allowance(
        address owner,
        address spender
    ) internal view returns (euint32) {
        if (TFHE.isInitialized(allowances[owner][spender])) {
            return allowances[owner][spender];
        } else {
            return TFHE.asEuint32(0);
        }
    }

    function _updateAllowance(
        address owner,
        address spender,
        euint32 amount
    ) internal {
        euint32 currentAllowance = _allowance(owner, spender);
        TFHE.optReq(TFHE.le(amount, currentAllowance));
        _approve(owner, spender, TFHE.sub(currentAllowance, amount));
    }

    // Transfers an encrypted amount.
    function _transfer(address from, address to, euint32 amount) internal {
        // Make sure the sender has enough tokens.
        TFHE.optReq(TFHE.le(amount, balances[from]));

        // Add to the balance of `to` and subract from the balance of `from`.
        balances[to] = balances[to] + amount;
        balances[from] = balances[from] - amount;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }
}
