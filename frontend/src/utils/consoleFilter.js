/**
 * Console Filter - Suppresses known non-critical warnings
 * MetaMask SES lockdown warnings are expected and safe
 */

const SUPPRESSED_PATTERNS = [
  'SES Removing unpermitted intrinsics',
  'Removing intrinsics.%DatePrototype%.toTemporalInstant',
  'lockdown-install.js',
  'Unknown portal type',
  'Third-party cookie will be blocked',
  'Source map error'
];

export function initConsoleFilter() {
  const originalError = console.error;
  const originalWarn = console.warn;
  
  console.error = function(...args) {
    const message = args.join(' ');
    if (SUPPRESSED_PATTERNS.some(pattern => message.includes(pattern))) {
      return; // Suppress
    }
    originalError.apply(console, args);
  };
  
  console.warn = function(...args) {
    const message = args.join(' ');
    if (SUPPRESSED_PATTERNS.some(pattern => message.includes(pattern))) {
      return; // Suppress
    }
    originalWarn.apply(console, args);
  };
}
