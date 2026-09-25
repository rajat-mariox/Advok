// SMS delivery through Twilio, used for login OTPs.
//
// Configured by TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN plus a sender: either
// TWILIO_MESSAGING_SERVICE_SID (recommended in the US, handles A2P 10DLC)
// or TWILIO_FROM (a Twilio phone number in E.164, e.g. +15551234567).
// Without these the OTP is logged and returned as devOtp (prototype mode).
import {
  TWILIO_ACCOUNT_SID,
  TWILIO_AUTH_TOKEN,
  TWILIO_FROM,
  TWILIO_MESSAGING_SERVICE_SID,
} from '../config';

export function isSmsConfigured(): boolean {
  return (
    TWILIO_ACCOUNT_SID.length > 0 &&
    TWILIO_AUTH_TOKEN.length > 0 &&
    (TWILIO_FROM.length > 0 || TWILIO_MESSAGING_SERVICE_SID.length > 0)
  );
}

export class SmsError extends Error {
  constructor(message: string, public readonly code?: number) {
    super(message);
  }
}

/**
 * Sends one SMS. `to` must be E.164 (+<country><number>). Throws SmsError
 * with Twilio's own message when delivery is rejected (unverified number on
 * a trial account, invalid number, etc.) so the caller can surface it.
 */
export async function sendSms(to: string, body: string): Promise<void> {
  if (!isSmsConfigured()) throw new SmsError('SMS is not configured');
  const params = new URLSearchParams({ To: to, Body: body });
  if (TWILIO_MESSAGING_SERVICE_SID) params.set('MessagingServiceSid', TWILIO_MESSAGING_SERVICE_SID);
  else params.set('From', TWILIO_FROM);
  const auth = Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64');
  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(TWILIO_ACCOUNT_SID)}/Messages.json`,
    {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params.toString(),
    },
  );
  const data = (await res.json().catch(() => ({}))) as { message?: string; code?: number; sid?: string; status?: string };
  if (!res.ok) {
    throw new SmsError(data.message ?? `Twilio error ${res.status}`, data.code);
  }
  console.log(`[SMS] ${to} -> ${data.status ?? 'queued'} (${data.sid ?? '?'})`);
}

/** E.164 from the app's separate dial code + local number, e.g. +1 / 9412340527. */
export function toE164(countryCode: string, phone: string): string {
  const digits = phone.replace(/\D/g, '');
  const cc = countryCode.replace(/\D/g, '');
  return `+${cc}${digits}`;
}

/**
 * Best-effort SMS for non-critical notices (booking accepted, etc.): skipped
 * with a log line when Twilio is not configured, never throws.
 */
export function notifySms(to: string, body: string): void {
  if (!isSmsConfigured()) {
    console.log(`[SMS skipped, Twilio not configured] ${to}: ${body}`);
    return;
  }
  sendSms(to, body).catch((err) => {
    console.error(`[SMS] to ${to} failed: ${err instanceof Error ? err.message : err}`);
  });
}
