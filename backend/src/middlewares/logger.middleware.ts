import type { NextFunction, Request, Response } from 'express';

/** Logs every API request with its status code and duration. */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const startedAt = Date.now();
  res.on('finish', () => {
    const time = new Date().toLocaleTimeString();
    console.log(
      `[${time}] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - startedAt}ms)`,
    );
  });
  next();
}
