import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { JWT_SECRET } from '../config';
import { findUserById } from '../db';
import type { Role, User } from '../types';

export interface AuthedRequest extends Request {
  user?: User;
}

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    res.status(401).json({ error: 'Missing Authorization header' });
    return;
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { sub: string };
    const user = findUserById(payload.sub);
    if (!user) {
      res.status(401).json({ error: 'User no longer exists' });
      return;
    }
    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function requireRole(...roles: Role[]) {
  return (req: AuthedRequest, res: Response, next: NextFunction): void => {
    requireAuth(req, res, () => {
      if (!req.user?.role || !roles.includes(req.user.role)) {
        res.status(403).json({ error: 'Forbidden for this role' });
        return;
      }
      next();
    });
  };
}
