/**
     * @title Marketplace (Classifieds)
     * @notice Implements the classifieds board market. The market will be governed
     * by an ERC20 token as currency; and an ERC721 token
     * that represents the ownership of the items being transacted.
     * Only posts for selling items are implemented.
     * The item tokenization is responsibility of the ERC721 contract  which should encode item details.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MarketPlace {
    event TransactionStatusChange(uint256 post, bytes32 status);

    IERC20 currencyToken;
    IERC721 itemToken;
    uint256 transactionCounter;

    struct Transaction {
        address seller;
        uint256 item;
        uint256 price;
        bytes32 status;
    }

    mapping(uint256 => Transaction) public transactions;

    // Default
    constructor (address _currencyTokenAddress, address _itemTokenAddress) {
        currencyToken = IERC20(_currencyTokenAddress);
        itemToken = IERC721(_itemTokenAddress);
        transactionCounter = 0;
    }

    /**
         * @dev Returns the details for a transaction.
         * @param _transaction The id for the transaction.
     */
    function getTransaction(uint256 _transaction)
        public
        virtual
        view
        returns(address, uint256, uint256, bytes32)
    {
        Transaction memory transaction = transactions[_transaction];
        return (transaction.seller, transaction.item, transaction.price, transaction.status);
    }

    /**
         * @dev Opens a new transaction. Puts _item in escrow.
         * @param _item The id for the item to transaction.
         * @param _price The amount of currency for which to transact with the item.
     */
    function newTransaction(uint256 _item, uint256 _price)
        public
        virtual
    {
        itemToken.transferFrom(msg.sender, address(this), _item);
        transactions[transactionCounter] = Transaction({
            seller: msg.sender,
            item: _item,
            price: _price,
            status: "Open"
        });

        transactionCounter += 1;
        emit TransactionStatusChange(transactionCounter - 1, "OPEN");
    }

    /**
     * @dev Executes a transaction. Must have approved this contract to transfer the
     * amount of currency specified to the seller. Transfers ownership of the
     * item to the buyer.
     * @param _transaction The id of an existing trade
     */
    function executeTransaction(uint256 _transaction)
        public
        virtual
    {
        Transaction memory transaction = transactions[_transaction];
        require(
            transaction.status == "OPEN",
            "ERROR: this transaction's status is not 'OPEN'."
        );
        currencyToken.transferFrom(msg.sender, transaction.seller, transaction.price);
        itemToken.transferFrom(address (this), msg.sender, transaction.item);
        transactions[_transaction].status = "EXECUTED";
        emit TransactionStatusChange(_transaction, "EXECUTED");
    }

    /**
        * @dev Cancels a transaction by the seller.
        * @param _transaction The transaction to be cancelled.
     */
    function cancelTransaction(uint256 _transaction)
        public
        virtual
    {
        Transaction memory transaction = transactions[_transaction];
        require(
            msg.sender == transaction.seller,
            "ERROR: Transaction may only be cancelled by the Seller."
        );
        require(
            transaction.status == "OPEN",
            "ERROR: Can not cancel...this transaction's status is not 'Open'."
        );
        itemToken.transferFrom(address(this), transaction.seller, transaction.item);
        transactions[_transaction].status = "CANCELLED";
        emit TransactionStatusChange(_transaction, "CANCELLED");
    }

}