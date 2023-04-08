// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IPUSHCommInterface {
    function sendNotification(
        address _channel,
        address _recipient,
        bytes calldata _identity
    ) external;
}

contract PriceMonitor is Ownable {
    using Strings for uint;
    using Strings for address;
    using Counters for Counters.Counter;

    struct PriceReport {
        uint256 productId;
        uint256 price;
        uint256 storeId;
        address reporter;
    }

    struct Product {
        string name;
        string brand;
        string description;
    }

    struct Store {
        uint256 id;
        string name;
        string location;
    }

    IPUSHCommInterface PUSHCOMM;

    Counters.Counter private _priceReportIds;
    Counters.Counter private _productIds;

    uint8 i_decimals;

    // Product[] s_productList;
    mapping(uint256 => Product) s_Products;
    Store[] s_storeList;
    mapping(uint256 => PriceReport) s_priceReports;

    event PriceReported(
        uint256 id,
        uint256 indexed productId,
        uint256 price,
        uint256 indexed storeId,
        address indexed reporter
    );

    event ProductCreated(
        uint256 id,
        string _name,
        string indexed _brand,
        string _description
    );

    constructor(uint8 _decimals) {
        i_decimals = _decimals;

        address EPNS_COMMV_1_5_STAGING = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa; //MUMBAI
        PUSHCOMM = IPUSHCommInterface(EPNS_COMMV_1_5_STAGING);
    }

    function addPriceReport(
        uint256 _productId,
        uint256 _price,
        uint256 _storeId
    ) public {
        uint256 currentPriceReportId = _priceReportIds.current();
        s_priceReports[currentPriceReportId] = PriceReport(
            _productId,
            _price,
            _storeId,
            msg.sender
        );
        _priceReportIds.increment();

        emit PriceReported(
            currentPriceReportId,
            _productId,
            _price,
            _storeId,
            msg.sender
        );

        address CHANNEL_ADDRESS = 0xCfA675376B1Aca49B30A2C836BB5D0834907A3cb;
        address to = 0xCfA675376B1Aca49B30A2C836BB5D0834907A3cb;

        // IPUSHCommInterface(EPNS_COMMV_1_5_STAGING).sendNotification(
        PUSHCOMM.sendNotification(
            CHANNEL_ADDRESS, // from channel
            to, // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
            bytes(
                string(
                    // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                    abi.encodePacked(
                        "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        "+", // segregator
                        "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                        "+", // segregator
                        "Price Report Alert", // this is notificaiton title
                        "+", // segregator
                        "Check this reported price! ",
                        " | reported by: ", // notification body
                        msg.sender.toHexString(), // notification body
                        " | Product: ", // notification body
                        _productId.toString(), // notification body
                        " | Price: ", // notification body
                        _price.toString(), // notification body
                        " PUSH to you!" // notification body
                    )
                )
            )
        );
    }

    function addProduct(
        string memory _name,
        string memory _brand,
        string memory _description
    ) public {
        uint256 currentProductId = _productIds.current();
        s_Products[currentProductId] = Product(_name, _brand, _description);
        _productIds.increment();

        emit ProductCreated(currentProductId, _name, _brand, _description);

        // TODO Notify via PUSH
    }

    /* getters */
    function getPriceReport(
        uint256 index
    ) public view returns (PriceReport memory) {
        return s_priceReports[index];
    }

    function getProduct(uint256 index) public view returns (Product memory) {
        return s_Products[index];
    }
}