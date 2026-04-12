import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export function TransactionModal({ isOpen, status, txHash, onClose }) {
  const steps = [
    { id: 'pending', label: 'Submitting Transaction', icon: '📤' },
    { id: 'confirming', label: 'Waiting for Confirmation', icon: '⏳' },
    { id: 'confirmed', label: 'Transaction Confirmed', icon: '✅' },
    { id: 'failed', label: 'Transaction Failed', icon: '❌' }
  ];

  const currentStep = steps.findIndex(s => s.id === status);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div 
          className="tx-modal-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div 
            className="tx-modal"
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
          >
            <h3>Transaction Status</h3>
            
            <div className="tx-steps">
              {steps.map((step, index) => (
                <div 
                  key={step.id}
                  className={`tx-step ${index <= currentStep ? 'active' : ''} ${index < currentStep ? 'completed' : ''}`}
                >
                  <div className="step-icon">{step.icon}</div>
                  <div className="step-label">{step.label}</div>
                  {index < steps.length - 1 && <div className="step-line" />}
                </div>
              ))}
            </div>

            {txHash && (
              <div className="tx-hash">
                <span>Transaction Hash:</span>
                <a 
                  href={`https://www.oklink.com/xlayer/tx/${txHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {txHash.slice(0, 10)}...{txHash.slice(-8)}
                </a>
              </div>
            )}

            {status === 'confirmed' && (
              <button className="btn btn-primary" onClick={onClose}>
                Continue
              </button>
            )}

            {status === 'failed' && (
              <button className="btn btn-secondary" onClick={onClose}>
                Close
              </button>
            )}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export function useTransaction() {
  const [isOpen, setIsOpen] = React.useState(false);
  const [status, setStatus] = React.useState('pending');
  const [txHash, setTxHash] = React.useState(null);

  const startTransaction = () => {
    setIsOpen(true);
    setStatus('pending');
    setTxHash(null);
  };

  const updateStatus = (newStatus, hash = null) => {
    setStatus(newStatus);
    if (hash) setTxHash(hash);
  };

  const closeModal = () => {
    setIsOpen(false);
  };

  return {
    isOpen,
    status,
    txHash,
    startTransaction,
    updateStatus,
    closeModal,
    TransactionModal: (props) => (
      <TransactionModal 
        isOpen={isOpen} 
        status={status} 
        txHash={txHash}
        onClose={closeModal}
        {...props}
      />
    )
  };
}
