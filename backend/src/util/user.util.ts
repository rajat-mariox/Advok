import type { User } from '../models';

/** Strips secret fields before sending a user over the wire. */
export function publicUser(user: User): Omit<User, 'passwordHash'> {
  const { passwordHash: _passwordHash, ...rest } = user;
  return rest;
}
