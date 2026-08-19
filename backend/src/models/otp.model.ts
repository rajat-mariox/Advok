export interface OtpRecord {
  phone: string;
  countryCode: string;
  country?: string;
  otp: string;
  expiresAt: number;
}
