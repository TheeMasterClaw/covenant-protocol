import { useState, useCallback } from 'react';

export type SessionConfig = {
  covenantAddress: string;
  paymentToken: string;
  maxAmount: bigint;
  durationDays: number;
};

export function useCovenantSession() {
  const [sessionActive, setSessionActive] = useState(false);
  const [sessionKey, setSessionKey] = useState<string | null>(null);

  // Biconomy-based session creation for recurring payments
  const createCovenantSession = useCallback(async (
    smartAccountClient: any,
    config: SessionConfig
  ) => {
    const validUntil = Math.floor(Date.now() / 1000) + (config.durationDays * 24 * 60 * 60);
    
    // Policy restricting to specific covenant contract, token, and max amount
    const policy = [{
      sessionKeyAddress: await smartAccountClient.getAddress(),
      contractAddress: config.covenantAddress,
      functionSelector: "processRecurringPayment(address,address,uint256)",
      rules: [
        {
          offset: 0,  // token address parameter
          condition: 0, // Equal
          referenceValue: config.paymentToken,
        },
        {
          offset: 64, // amount parameter (2 addresses = 64 bytes)
          condition: 1, // Less than or equal
          referenceValue: config.maxAmount.toString(),
        },
      ],
      interval: {
        validUntil,
        validAfter: Math.floor(Date.now() / 1000),
      },
      valueLimit: 0n,
    }];

    // Dynamically import Biconomy to avoid bundling if not used
    const { createSession, PaymasterMode } = await import('@biconomy/account');

    const { wait, session } = await createSession(
      smartAccountClient,
      policy,
      null,
      { paymasterServiceData: { mode: PaymasterMode.SPONSORED } }
    );

    await wait();
    setSessionActive(true);
    setSessionKey(session);
    
    return session;
  }, []);

  const clearSession = useCallback(() => {
    setSessionActive(false);
    setSessionKey(null);
  }, []);

  return {
    createCovenantSession,
    sessionActive,
    sessionKey,
    clearSession,
  };
}
