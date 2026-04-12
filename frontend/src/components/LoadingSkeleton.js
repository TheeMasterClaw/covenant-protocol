import React from 'react';
import { motion } from 'framer-motion';

export function LoadingCard() {
  return (
    <motion.div 
      className="card loading-card"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
    >
      <div className="skeleton-header">
        <div className="skeleton-icon" />
        <div className="skeleton-text short" />
      </div>
      <div className="skeleton-text long" />
      <div className="skeleton-text medium" />
    </motion.div>
  );
}

export function LoadingCovenantItem() {
  return (
    <div className="covenant-item loading-item">
      <div className="skeleton-avatar" />
      <div className="skeleton-info">
        <div className="skeleton-text medium" />
        <div className="skeleton-text short" />
      </div>
      <div className="skeleton-amount" />
      <div className="skeleton-status" />
    </div>
  );
}

export function PageLoader() {
  return (
    <div className="page-loader">
      <motion.div 
        className="loader-spinner"
        animate={{ rotate: 360 }}
        transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
      />
      <p>Loading COVENANT Protocol...</p>
    </div>
  );
}

export function LoadingAgents() {
  return (
    <div className="agent-grid loading">
      {[1, 2, 3, 4].map((i) => (
        <div key={i} className="agent-card skeleton">
          <div className="skeleton-avatar-large" />
          <div className="skeleton-text medium" />
          <div className="skeleton-text short" />
          <div className="skeleton-skills">
            <div className="skeleton-skill" />
            <div className="skeleton-skill" />
          </div>
        </div>
      ))}
    </div>
  );
}
