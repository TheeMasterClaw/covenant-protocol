import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { xLayer } from 'wagmi/chains';
import { xLayerTestnet } from 'wagmi/chains';

// X Layer Mainnet configuration
const xLayerMainnet = {
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
};

// X Layer Testnet configuration
const xLayerTest = {
  id: 195,
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
};

export const config = getDefaultConfig({
  appName: 'COVENANT Protocol',
  projectId: process.env.REACT_APP_WALLETCONNECT_PROJECT_ID || 'covenant-protocol-demo',
  chains: [xLayerTest, xLayerMainnet],
  ssr: false,
});
