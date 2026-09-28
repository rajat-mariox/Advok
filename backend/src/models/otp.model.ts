export interface OtpRecord {
  phone: string;
  countryCode: string;
  country?: string;
  /** Empty when Twilio Verify holds the code (viaVerify). */
  otp: string;
  expiresAt: number;
  /** True when Twilio Verify sent the code and must check it. */
  viaVerify?: boolean;
}
