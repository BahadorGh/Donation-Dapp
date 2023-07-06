// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
// import {CampaignTypes} from "./CampaignTypes.sol";

contract CrowdFunding is Ownable {
    error LowEtherAmount(uint minAmount, uint payedAmount);
    error DeadLine(uint campaingDeadline, uint requestTime);

    struct Campaign {
        address owner;
        bool payedOut;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public platformTax;
    uint256 public numberOfCampaigns;

    event Action (
        uint256 id,
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    modifier PrivilageEntity(uint _id) {
        _privilagedEntity(_id);
        _;
    }

    modifier NotNull(
        string memory title,
        string memory description,
        uint256 target,
        uint256 deadline,
        string memory image) {
            _nullChecker(title, description, target, deadline, image);
            _;
        }

    constructor(uint256 _platformTax) {
        platformTax = _platformTax;
    }

    function createCampaign(
        address _owner, 
        string memory _title, 
        string memory _description,
        uint256 _target, 
        uint256 _deadline, 
        string memory _image
        ) public NotNull(_title, _description, _target, _deadline, _image) returns (uint256) {
            require(block.timestamp <  _deadline, "The deadline should be a date in the future.");
            Campaign storage campaign = campaigns[numberOfCampaigns];
            numberOfCampaigns++;

            campaign.owner = _owner;
            campaign.title = _title;
            campaign.description = _description;
            campaign.target = _target;
            campaign.deadline = _deadline;
            campaign.amountCollected = 0;
            campaign.image = _image;
            campaign.payedOut = false;

            emit Action (
                numberOfCampaigns,
                "Campaign Created",
                msg.sender,
                block.timestamp
            );

            return numberOfCampaigns - 1;
    }

    function updateCampaign(
        uint256 _id,
        string memory _title, 
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
         ) public PrivilageEntity(_id) NotNull(_title, _description, _target, _deadline, _image) returns (bool) {
            require(block.timestamp <  _deadline, "The deadline should be a date in the future.");
            Campaign storage campaign = campaigns[_id];
            require(campaign.amountCollected == 0, "Can't update due to amount collected");
            require(campaign.owner > address(0), "No campaign exist with this ID");

            campaign.title = _title;
            campaign.description = _description;
            campaign.target = _target;
            campaign.deadline = _deadline;
            campaign.amountCollected = 0;
            campaign.image = _image;
            campaign.payedOut = false;

            emit Action (
                _id,
                "Campaign Updated",
                msg.sender,
                block.timestamp
            );
            return true;
    }



    function donateToCampaign(uint256 _id) public payable {
        if(msg.value == 0 wei) revert LowEtherAmount({minAmount: 1 wei, payedAmount: msg.value});
        Campaign storage campaign = campaigns[_id];
        if(campaign.deadline < block.timestamp) {
            revert DeadLine(
                {
                    campaingDeadline:campaigns[_id].deadline,
                    requestTime: block.timestamp
                }
            );
        }
        uint256 amount = msg.value;

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        campaign.amountCollected = campaign.amountCollected + amount;
        emit Action (
            _id,
            "Donation To The Campaign",
            msg.sender,
            block.timestamp
        );
    }

    function payOutToCampaignTeam(uint256 _id) public PrivilageEntity(_id) returns (bool) {
        if(campaigns[_id].payedOut == true) revert("Funds withdrawed before");
        if(msg.sender != address(owner())) {
            if(campaigns[_id].deadline > block.timestamp) {
                revert DeadLine(
                    {
                        campaingDeadline:campaigns[_id].deadline,
                        requestTime: block.timestamp
                    }
                );
            }
        }

        campaigns[_id].payedOut = true;
        (uint256 raisedAmount, uint256 taxAmount) = _calculateTax(_id);
        _payTo(campaigns[_id].owner, (raisedAmount - taxAmount));
        _payTo(owner(), taxAmount);
        emit Action (
            _id,
            "Funds Withdrawal",
            msg.sender,
            block.timestamp
        );
        return true;
    }

    function deleteCampaign(uint256 _id) public PrivilageEntity(_id) returns (bool) {
        // to check if a capmpaign with specific id exists.
        require(campaigns[_id].owner > address(0), "No campaign exist with this ID");
        if(campaigns[_id].amountCollected > 0) {
            _refundDonators(_id);
        }
        delete campaigns[_id];

        emit Action (
            _id,
            "Campaign Deleted",
            msg.sender,
            block.timestamp
        );

        numberOfCampaigns -= 1;
        return true;
    }

    function _refundDonators(uint _id) internal {
        Campaign storage campaign = campaigns[_id]; 
        for(uint i; i < campaign.donators.length; i++) {
            _payTo(campaign.donators[i], campaign.donations[i]);
            campaign.donations[i] = 0;
            campaign.amountCollected = 0;
        }
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    function changeTax(uint256 _platformTax) public onlyOwner {
        platformTax = _platformTax;
    }

    function haltCampaign(uint256 _id) public onlyOwner {
        campaigns[_id].deadline = block.timestamp;

        emit Action (
            _id,
            "Campaign halted",
            msg.sender,
            block.timestamp
        );
    }

    function _calculateTax(uint256 _id) internal view returns (uint, uint) {
        uint raised = campaigns[_id].amountCollected;
        uint tax = (raised * platformTax) / 100;
        return (raised, tax);
    }

    function _payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }

    function _nullChecker(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
        ) internal pure {
            require((
                    bytes(_title).length > 0 
                    && bytes(_description).length > 0 
                    && _target > 0 
                    && _deadline > 0 
                    && bytes(_image).length > 0
                ), "Null value not acceptable");
    }

    function _privilagedEntity(uint256 _id) internal view {
        require(
            msg.sender == campaigns[_id].owner ||
            msg.sender == owner(),
            "Unauthorized Entity"
        );
    } 
}