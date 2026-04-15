import { getDefaultConfig } from '@rainbow-me/rainbowkit';
// X Layer Mainnet configuration
export const xLayerMainnet = {
  id: 196,
  name: 'X Layer Mainnet',
  nativeCurrency: {
    decimals: 18,
    name: 'OKB',
    symbol: 'OKB',
  },
  rpcUrls: {
    public: { http: ['https://rpc.xlayer.tech'] },
    default: { http: ['https://rpc.xlayer.tech'] },
  },
  blockExplorers: {
    default: { name: 'X Layer Explorer', url: 'https://www.oklink.com/xlayer' },
  },
} as const;

// X Layer Testnet configuration
export const xLayerTest = {
  id: 1952,
  name: 'X Layer Testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'OKB',
    symbol: 'OKB',
  },
  rpcUrls: {
    public: { http: ['https://testrpc.xlayer.tech'] },
    default: { http: ['https://testrpc.xlayer.tech'] },
  },
  blockExplorers: {
    default: { name: 'X Layer Testnet Explorer', url: 'https://www.oklink.com/xlayer-test' },
  },
  testnet: true,
} as const;

export const config = getDefaultConfig({
  appName: 'COVENANT Protocol',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'covenant-protocol-demo',
  chains: [xLayerTest, xLayerMainnet],
  ssr: true,
});
