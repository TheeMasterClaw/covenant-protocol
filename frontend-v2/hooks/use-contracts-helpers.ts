import { parseEther, formatEther, encodeAbiParameters, parseAbiParameters, pad, toHex, stringToHex } from 'viem';

export { parseEther, formatEther };

export function encodeBytes32String(str: string): `0x${string}` {
  return pad(stringToHex(str, { size: 32 }), { dir: 'right' }) as `0x${string}`;
}
