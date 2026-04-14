import { CovenantSDK } from '../sdk';

export type PaymentSchedule = {
  frequency: 'daily' | 'weekly' | 'monthly';
  amount: bigint;
  token: string;
  startTime: number;
  endTime: number;
};

export type SessionKey = {
  sessionKeyAddress: string;
  sessionData: string;
  validUntil: number;
};

/**
 * Smart account extensions for the COVENANT TypeScript SDK.
 */
export class CovenantSmartAccount {
  private sdk: CovenantSDK;
  private smartAccount: any;

  constructor(sdk: CovenantSDK, smartAccount: any) {
    this.sdk = sdk;
    this.smartAccount = smartAccount;
  }

  async createCovenant(
    counterparty: string,
    terms: string,
    paymentSchedule: PaymentSchedule
  ): Promise<string> {
    if (!this.smartAccount) {
      throw new Error('Smart account not initialized');
    }

    const userOpHash = await this.smartAccount.sendUserOperation({
      calls: [{
        to: this.sdk.addresses.covenantFactory,
        data: this.sdk.covenantFactory.interface.encodeFunctionData('createCovenant', [
          counterparty,
          terms,
          paymentSchedule,
        ]),
      }],
    });

    return userOpHash;
  }

  async setupRecurringPaymentSession(
    covenantId: string,
    covenantAddress: string,
    maxAmount: bigint,
    durationDays: number,
    paymentToken: string
  ): Promise<SessionKey> {
    const validUntil = Math.floor(Date.now() / 1000) + (durationDays * 24 * 60 * 60);

    return {
      sessionKeyAddress: await this.smartAccount.getAddress(),
      sessionData: JSON.stringify({
        covenantId,
        covenantAddress,
        maxAmount: maxAmount.toString(),
        paymentToken,
        validUntil,
      }),
      validUntil,
    };
  }

  async processRecurringPayment(
    covenantAddress: string,
    paymentToken: string,
    amount: bigint
  ): Promise<string> {
    const userOpHash = await this.smartAccount.sendUserOperation({
      calls: [{
        to: covenantAddress,
        data: this.sdk.covenantFactory.interface.encodeFunctionData(
          'processRecurringPayment',
          [paymentToken, amount]
        ),
      }],
    });

    return userOpHash;
  }
}
