import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http } from 'viem';
import { createConfig, WagmiProvider } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';

const projectId = import.meta.env.VITE_PROJECT_ID;

const config = createConfig(
  getDefaultConfig({
    appName: 'HoldPay',
    projectId,
    chains: [sepolia],
    transports: {
      [sepolia.id]: http(import.meta.env.VITE_SEPOLIA_RPC_URL),
    },
  })
);

const queryClient = new QueryClient();

export function Providers({ children }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}