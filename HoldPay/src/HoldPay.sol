// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract HoldPay is Ownable{
    enum Status {Pending, upFrontReleased, Completed, Cancelled }

    struct Escrow{
        address client;
        address provider;
        uint256 totalAmount;
        uint256 upFrontPercentage;
        uint256 upFrontAmount;
        uint256 releasedAmount;
        Status status;
        bool clientApprovedUpfront;
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public nextId;

    event escrowCreated(uint256 id, address client, address provider, uint256 totalAmount, uint256 upFrontPercentage );
    event upFrontApproved(uint256 id);
    event upFrontReleased(uint256 id, uint256 amount);
    event delievryConfirmed(uint256 id, uint256 finalAmount);
    event escrowCancelled(uint256 id);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function createEscrow(address provider, uint256 upFrontPercentage) external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(upFrontPercentage <= 0, "Upfront percentage invalid");
        uint256 id = nextId++;
        uint256 upFrontAmt = (msg.value * upFrontPercentage) / 100;


        escrows[id] = Escrow({
            client: msg.sender,
            provider: provider,
            totalAmount: msg.value,
            upFrontPercentage: upFrontPercentage,
            upFrontAmount: upFrontAmt,
            releasedAmount: 0,
            status: Status.Pending,
            clientApprovedUpfront: false
        });

        emit escrowCreated(id, msg.sender, provider, msg.value, upFrontPercentage);
    }

    function approveUpfront(uint256 id) external {
        Escrow storage escrow = escrows[id];
        require(msg.sender == escrow.client, "Only client");
        require(escrow.status == Status.Pending, "Invalid status");
        require(escrow.upFrontAmount > 0, "No upfront");

        escrow.clientApprovedUpfront = true;
        emit upFrontApproved(id);
    }

    function releaseUpfront(uint256 id) external {
        Escrow storage escrow = escrows[id];

        require(msg.sender == escrow.provider, "Only provider");
        require(escrow.status == Status.Pending, "Invalid status");
        require(escrow.clientApprovedUpfront, "Client not approved");
        require(escrow.upFrontAmount > 0, "No upfront");

        escrow.releasedAmount += escrow.upFrontAmount;
        escrow.status = Status.upFrontReleased;
        payable(escrow.provider).transfer(escrow.upFrontAmount);
        emit upFrontReleased(id, escrow.upFrontAmount);
    }

    function confirmDelivery(uint256 id) external {
        Escrow storage escrow = escrows[id];
        require(msg.sender == escrow.client || msg.sender == escrow.provider, "Unauthorized");
        require(escrow.status != Status.Completed && escrow.status != Status.Cancelled, "Invalid Status");

        uint256 remaining = escrow.totalAmount - escrow.releasedAmount;
        escrow.releasedAmount = escrow.totalAmount;
        escrow.status = Status.Completed;
        payable(escrow.provider).transfer(remaining);
        emit delievryConfirmed(id, remaining);
    }

    function cancelEscrow(uint256 id) external {
        Escrow storage escrow = escrows[id];
        require(msg.sender == escrow.client || msg.sender == escrow.provider, "Unauthorized");
        require(escrow.status != Status.Completed, "Already completed");

        uint256 refund = escrow.totalAmount - escrow.releasedAmount;
        escrow.status = Status.Cancelled;
        if (refund > 0) {
            payable(escrow.client).transfer(refund);
        }
        emit escrowCancelled(id);
    }

    function getEscrow(uint256 id) external view returns(Escrow memory) {
        return escrows[id];
    }
}