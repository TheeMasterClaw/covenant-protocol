import React from 'react';
import { motion } from 'framer-motion';

export function ThemeToggle({ theme, toggleTheme }) {
  return (
    <button 
      className="theme-toggle"
      onClick={toggleTheme}
      aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
    >
      <motion.div
        className="toggle-track"
        animate={{ backgroundColor: theme === 'dark' ? '#2a2a3a' : '#e0e0e0' }}
      >
        <motion.div
          className="toggle-thumb"
          animate={{ 
            x: theme === 'dark' ? 2 : 26,
            backgroundColor: theme === 'dark' ? '#00d4ff' : '#ffaa00'
          }}
          transition={{ type: "spring", stiffness: 500, damping: 30 }}
        >
          {theme === 'dark' ? '🌙' : '☀️'}
        </motion.div>
      </motion.div>
    </button>
  );
}
