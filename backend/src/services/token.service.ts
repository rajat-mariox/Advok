import jwt from 'jsonwebtoken';
import { JWT_SECRET } from '../config';

/** Signs the JWT the app/admin panel sends back in the Authorization header. */
export function signToken(userId: string, ttl: string): string {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: ttl } as jwt.SignOptions);
}
