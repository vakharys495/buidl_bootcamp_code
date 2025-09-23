import React, { useState, useEffect } from 'react';
import { useAccount, useWriteContract, usePublicClient, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import HoldPayAbi from './abis/HoldPay.json';
import { sepolia } from 'wagmi/chains';
import './App.css';

const HOLD_PAY_ADDRESS = import.meta.env.VITE_ESCROW_ADDRESS;

function App() {
  const { address, isConnected } = useAccount();
  const [providerAddr, setProviderAddr] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [upfrontPercent, setUpfrontPercent] = useState('0');
  const [escrowId, setEscrowId] = useState('');
  const [escrows, setEscrows] = useState([]);
  const [txHash, setTxHash] = useState();
  const publicClient = usePublicClient();

  const { writeContract } = useWriteContract();
  const { isLoading: isTxLoading } = useWaitForTransactionReceipt({
    hash: txHash,
    onSuccess: () => fetchUserEscrows(),
  });

  // Fetch user's escrows
  const fetchUserEscrows = async () => {
    if (!address || !publicClient) return;
    const userEscrows = [];
    let id = 0;
    while (true) {
      try {
        const data = await publicClient.readContract({
          address: HOLD_PAY_ADDRESS,
          abi: HoldPayAbi,
          functionName: 'getEscrow',
          args: [BigInt(id)],
        });
        if (data.totalAmount === 0n) break;
        if (data.client.toLowerCase() === address.toLowerCase() || data.provider.toLowerCase() === address.toLowerCase()) {
          userEscrows.push(data);
        }
        id++;
      } catch {
        break;
      }
    }
    setEscrows(userEscrows);
  };

  useEffect(() => {
    if (isConnected) fetchUserEscrows();
  }, [address, isConnected]);

  const handleCreate = () => {
    if (!totalAmount || !providerAddr || !/^(0x)?[0-9a-fA-F]{40}$/.test(providerAddr)) return;
    writeContract({
      address: HOLD_PAY_ADDRESS,
      abi: HoldPayAbi,
      functionName: 'createEscrow',
      args: [providerAddr, BigInt(upfrontPercent)],
      value: parseEther(totalAmount),
    }, {
      onSuccess: (hash) => setTxHash(hash),
      onError: (error) => console.error('Create failed:', error),
    });
    setTotalAmount('');
    setProviderAddr('');
    setUpfrontPercent('0');
  };

  const handleApproveUpfront = () => {
    if (!escrowId) return;
    writeContract({
      address: HOLD_PAY_ADDRESS,
      abi: HoldPayAbi,
      functionName: 'approveUpfront',
      args: [BigInt(escrowId)],
    }, {
      onSuccess: (hash) => setTxHash(hash),
    });
  };

  const handleReleaseUpfront = () => {
    if (!escrowId) return;
    writeContract({
      address: HOLD_PAY_ADDRESS,
      abi: HoldPayAbi,
      functionName: 'releaseUpfront',
      args: [BigInt(escrowId)],
    }, {
      onSuccess: (hash) => setTxHash(hash),
    });
  };

  const handleConfirm = () => {
    if (!escrowId) return;
    writeContract({
      address: HOLD_PAY_ADDRESS,
      abi: HoldPayAbi,
      functionName: 'confirmDelivery',
      args: [BigInt(escrowId)],
    }, {
      onSuccess: (hash) => setTxHash(hash),
    });
  };

  const handleCancel = () => {
    if (!escrowId) return;
    writeContract({
      address: HOLD_PAY_ADDRESS,
      abi: HoldPayAbi,
      functionName: 'cancelEscrow',
      args: [BigInt(escrowId)],
    }, {
      onSuccess: (hash) => setTxHash(hash),
    });
  };

  return (
    <div className="container">
      <h1>HoldPay</h1>
      <ConnectButton />
      {isConnected && (
        <>
          <button onClick={fetchUserEscrows} disabled={isTxLoading}>
            Refresh Escrows
          </button>
          <div className="section">
            <h2>Create Escrow (Client)</h2>
            <input
              placeholder="Provider Address (0x...)"
              value={providerAddr}
              onChange={(e) => setProviderAddr(e.target.value)}
            />
            <input
              type="number"
              placeholder="Total Amount (ETH)"
              value={totalAmount}
              onChange={(e) => setTotalAmount(e.target.value)}
            />
            <input
              type="number"
              placeholder="Upfront % (0-100)"
              value={upfrontPercent}
              onChange={(e) => setUpfrontPercent(e.target.value)}
            />
            <button onClick={handleCreate} disabled={isTxLoading}>
              {isTxLoading ? 'Processing...' : 'Create Escrow'}
            </button>
          </div>
          <div className="section">
            <h2>Manage Escrow</h2>
            <input
              type="number"
              placeholder="Escrow ID"
              value={escrowId}
              onChange={(e) => setEscrowId(e.target.value)}
            />
            <button onClick={handleApproveUpfront} disabled={isTxLoading}>
              Approve Upfront (Client)
            </button>
            <button onClick={handleReleaseUpfront} disabled={isTxLoading}>
              Release Upfront (Provider)
            </button>
            <button onClick={handleConfirm} disabled={isTxLoading}>
              Confirm Delivery (Client)
            </button>
            <button onClick={handleCancel} disabled={isTxLoading}>
              Cancel Escrow
            </button>
          </div>
          <div className="section">
            <h2>Your Escrows ({escrows.length})</h2>
            {escrows.map((esc, index) => (
              <div key={index} className="escrow-card">
                <p>ID: {index}</p>
                <p>Client: {esc.client}</p>
                <p>Provider: {esc.provider}</p>
                <p>Total: {(Number(esc.totalAmount) / 1e18).toFixed(4)} ETH</p>
                <p>Released: {(Number(esc.releasedAmount) / 1e18).toFixed(4)} ETH</p>
                <p>Upfront: {(Number(esc.upfrontAmount) / 1e18).toFixed(4)} ETH ({esc.upfrontPercentage}%)</p>
                <p>Status: {['Pending', 'UpfrontReleased', 'Completed', 'Cancelled'][esc.status]}</p>
                <p>Upfront Approved: {esc.clientApprovedUpfront ? 'Yes' : 'No'}</p>
              </div>
            ))}
          </div>
          {txHash && (
            <p className="transaction">
              Transaction: <a href={`https://sepolia.etherscan.io/tx/${txHash}`} target="_blank" rel="noopener noreferrer">{txHash}</a>
            </p>
          )}
        </>
      )}
    </div>
  );
}

export default App;