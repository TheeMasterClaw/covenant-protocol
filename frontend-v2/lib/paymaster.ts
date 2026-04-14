import { createPaymasterClient } from "viem/account-abstraction";
import { http } from "viem";

const PIMLICO_API_KEY = process.env.NEXT_PUBLIC_PIMLICO_API_KEY;

// Pimlico paymaster for X Layer Testnet
export const paymasterClient = createPaymasterClient({
  transport: http(
    `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${PIMLICO_API_KEY}`
  ),
});

// Eligibility check for sponsored transactions
export async function checkSponsorshipEligibility(
  userAddress: string,
  operation: 'create_covenant' | 'dispute_resolution' | 'reputation_stake' | 'recurring_payment'
): Promise<{ eligible: boolean; reason?: string }> {
  try {
    const response = await fetch('/api/sponsor-check', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userAddress, operation }),
    });
    
    return await response.json();
  } catch (error) {
    // Default to eligible on error (fail open for UX)
    return { eligible: true };
  }
}

// Whitelist of covenant operations that are sponsored
export const SPONSORED_OPERATIONS = [
  'createCovenant',
  'submitDispute', 
  'stakeReputation',
  'processRecurringPayment',
  'resolveDispute',
] as const;

export type SponsoredOperation = typeof SPONSORED_OPERATIONS[number];
