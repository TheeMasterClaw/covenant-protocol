import React, { useEffect, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export function ToastContainer({ toasts, removeToast }) {
  return (
    <div className="toast-container">
      <AnimatePresence>
        {toasts.map((toast) => (
          <Toast key={toast.id} toast={toast} onClose={() => removeToast(toast.id)} />
        ))}
      </AnimatePresence>
    </div>
  );
}

function Toast({ toast, onClose }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 5000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const icons = {
    success: '✅',
    error: '❌',
    warning: '⚠️',
    info: 'ℹ️'
  };

  return (
    <motion.div
      className={`toast toast-${toast.type}`}
      initial={{ opacity: 0, y: 50, scale: 0.9 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, x: 100 }}
      layout
    >
      <span className="toast-icon">{icons[toast.type]}</span>
      <div className="toast-content">
        <h4>{toast.title}</h4>
        <p>{toast.message}</p>
      </div>
      <button className="toast-close" onClick={onClose}>×</button>
    </motion.div>
  );
}

// Hook for using toasts
export function useToast() {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((type, title, message) => {
    const id = Date.now();
    setToasts((prev) => [...prev, { id, type, title, message }]);
    return id;
  }, []);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const success = useCallback((title, message) => addToast('success', title, message), [addToast]);
  const error = useCallback((title, message) => addToast('error', title, message), [addToast]);
  const warning = useCallback((title, message) => addToast('warning', title, message), [addToast]);
  const info = useCallback((title, message) => addToast('info', title, message), [addToast]);

  return { toasts, removeToast, success, error, warning, info };
}
