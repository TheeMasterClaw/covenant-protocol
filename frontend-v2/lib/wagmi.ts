import { WagmiAdapter } from '@reown/appkit-adapter-wagmi';
import { cookieStorage, createStorage } from '@wagmi/core';

// X Layer Testnet
export const xLayerTestnet = {
  id: 1952,
  name: 'X Layer Testnet',
  nativeCurrency: { decimals: 18, name: 'OKB', symbol: 'OKB' },
  rpcUrls: {
    public: { http: ['https://testrpc.xlayer.tech'] },
    default: { http: ['https://testrpc.xlayer.tech'] },
  },
  blockExplorers: {
    default: { name: 'X Layer Testnet Explorer', url: 'https://www.oklink.com/xlayer-test' },
  },
  testnet: true,
} as const;

// X Layer Mainnet
export const xLayerMainnet = {
  id: 196,
  name: 'X Layer Mainnet',
  nativeCurrency: { decimals: 18, name: 'OKB', symbol: 'OKB' },
  rpcUrls: {
    public: { http: ['https://rpc.xlayer.tech'] },
    default: { http: ['https://rpc.xlayer.tech'] },
  },
  blockExplorers: {
    default: { name: 'X Layer Explorer', url: 'https://www.oklink.com/xlayer' },
  },
} as const;

// Reown (WalletConnect) project ID — get yours at https://cloud.reown.com
export const projectId = process.env.NEXT_PUBLIC_PROJECT_ID || '21fef48091f12692cad574a6f7753643';

export const networks = [xLayerTestnet, xLayerMainnet];

export const wagmiAdapter = new WagmiAdapter({
  storage: createStorage({ storage: cookieStorage }),
  ssr: true,
  projectId,
  networks,
});

export const config = wagmiAdapter.wagmiConfig;
