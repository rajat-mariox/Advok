/** A phone number is usable when it has at least 6 digits. */
export function isValidPhone(phone: unknown): phone is string {
  return typeof phone === 'string' && phone.replace(/\D/g, '').length >= 6;
}
