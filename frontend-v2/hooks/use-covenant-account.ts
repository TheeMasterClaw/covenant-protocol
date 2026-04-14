import { useState, useCallback, useEffect } from 'react';
import { useAccount, useWalletClient } from 'wagmi';
import { createSmartAccountClient } from 'permissionless';
import { createPaymasterClient, toSimpleSmartAccount } from 'viem/account-abstraction';
import { http } from 'viem';
import { xLayerTest, xLayer } from 'wagmi/chains';

const PAYMASTER_URL = `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${process.env.NEXT_PUBLIC_PIMLICO_API_KEY}`;
const BUNDLER_URL = `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${process.env.NEXT_PUBLIC_PIMLICO_API_KEY}`;

export function useCovenantAccount() {
  const { address, isConnected } = useAccount();
  const { data: walletClient } = useWalletClient();
  const [smartAccount, setSmartAccount] = useState<any>(null);
  const [smartAccountAddress, setSmartAccountAddress] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const createSmartAccount = useCallback(async () => {
    if (!walletClient || !isConnected) return;
    
    setIsLoading(true);
    setError(null);
    
    try {
      const account = await toSimpleSmartAccount({
        client: walletClient as any,
        owner: walletClient.account as any,
      });

      const paymasterClient = createPaymasterClient({
        transport: http(PAYMASTER_URL),
      });

      const client = createSmartAccountClient({
        account,
        paymaster: paymasterClient,
        chain: xLayerTest,
        bundlerTransport: http(BUNDLER_URL),
        userOperation: {
          estimateFeesPerGas: async () => {
            return (await paymasterClient.getUserOperationGasPrice()).fast;
          },
        },
      });

      const saAddress = await account.getAddress();
      setSmartAccount(client);
      setSmartAccountAddress(saAddress);
      
      localStorage.setItem('covenant_smart_account', saAddress);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to create smart account'));
    } finally {
      setIsLoading(false);
    }
  }, [walletClient, isConnected]);

  useEffect(() => {
    if (isConnected && !smartAccount) {
      createSmartAccount();
    }
  }, [isConnected, smartAccount, createSmartAccount]);

  const sendGaslessTransaction = useCallback(async (calls: Array<{ to: string; data?: string; value?: bigint }>) => {
    if (!smartAccount) throw new Error('Smart account not initialized');
    
    const userOpHash = await smartAccount.sendUserOperation({
      calls: calls as any,
    });

    return smartAccount.waitForUserOperationReceipt({ hash: userOpHash });
  }, [smartAccount]);

  return {
    eoaAddress: address,
    smartAccount,
    smartAccountAddress,
    isLoading,
    error,
    createSmartAccount,
    sendGaslessTransaction,
  };
}
