// Single import point for all data types: `import { User, Booking } from '../models'`.
import type { Booking } from './booking.model';
import type { CmsPage } from './cms.model';
import type { OtpRecord } from './otp.model';
import type { User } from './user.model';

export * from './booking.model';
export * from './cms.model';
export * from './otp.model';
export * from './user.model';

/** Everything the store holds — one collection per field. */
export interface DbShape {
  users: User[];
  otps: OtpRecord[];
  cmsPages?: CmsPage[];
  bookings?: Booking[];
}
