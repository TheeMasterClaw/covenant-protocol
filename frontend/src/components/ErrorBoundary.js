import React from 'react';

export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('COVENANT Error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <div className="error-icon">⚠️</div>
          <h2>Something went wrong</h2>
          <p>The protocol encountered an unexpected error.</p>
          <details>
            <summary>Error details</summary>
            <pre>{this.state.error?.toString()}</pre>
          </details>
          <button 
            className="btn btn-primary"
            onClick={() => window.location.reload()}
          >
            Reload Application
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

export function WalletError({ error, onRetry }) {
  const errors = {
    'No ethereum provider': {
      title: 'Wallet Not Found',
      message: 'Please install MetaMask or another Web3 wallet.',
      action: 'Install MetaMask'
    },
    'User rejected': {
      title: 'Connection Rejected',
      message: 'You rejected the wallet connection request.',
      action: 'Try Again'
    },
    'Network mismatch': {
      title: 'Wrong Network',
      message: 'Please switch to X Layer network in your wallet.',
      action: 'Switch Network'
    }
  };

  const errorInfo = errors[error?.message] || {
    title: 'Wallet Error',
    message: error?.message || 'Unknown error occurred',
    action: 'Retry'
  };

  return (
    <div className="wallet-error">
      <div className="error-icon">🔒</div>
      <h3>{errorInfo.title}</h3>
      <p>{errorInfo.message}</p>
      <button className="btn btn-primary" onClick={onRetry}>
        {errorInfo.action}
      </button>
    </div>
  );
}

export function EmptyState({ icon, title, message, action }) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <h3>{title}</h3>
      <p>{message}</p>
      {action && <button className="btn btn-primary" onClick={action.onClick}>{action.label}</button>}
    </div>
  );
}
