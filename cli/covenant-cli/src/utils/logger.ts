import * as winston from 'winston';
import chalk from 'chalk';

const { combine, timestamp, printf, colorize, errors } = winston.format;

const consoleFormat = printf(({ level, message, timestamp, stack }) => {
  const ts = chalk.gray(`[${timestamp as string}]`);
  const msg = `${ts} ${level}: ${message as string}`;
  return stack ? `${msg}\n${stack as string}` : msg;
});

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  defaultMeta: { service: 'covenant-cli' },
  transports: [
    new winston.transports.Console({
      format: combine(
        timestamp({ format: 'HH:mm:ss' }),
        colorize({ all: true }),
        errors({ stack: true }),
        consoleFormat
      )
    })
  ]
});

export const logSuccess = (msg: string): void => {
  console.log(chalk.green('✔'), msg);
};

export const logError = (msg: string): void => {
  console.error(chalk.red('✖'), msg);
};

export const logWarning = (msg: string): void => {
  console.warn(chalk.yellow('⚠'), msg);
};

export const logInfo = (msg: string): void => {
  console.info(chalk.blue('ℹ'), msg);
};

export const logTable = (data: Record<string, string | number | boolean | undefined>): void => {
  const maxKeyLength = Math.max(...Object.keys(data).map(k => k.length));
  Object.entries(data).forEach(([key, value]) => {
    const paddedKey = key.padEnd(maxKeyLength, ' ');
    console.log(`  ${chalk.cyan(paddedKey)} : ${value ?? chalk.gray('null')}`);
  });
};

export const logDivider = (): void => {
  console.log(chalk.gray('─'.repeat(60)));
};
