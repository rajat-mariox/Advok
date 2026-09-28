// SMS through Twilio: login OTPs and the attorney-details notice.
//
// Two ways the OTP can go out, picked by otpMode():
//   verify  TWILIO_VERIFY_SERVICE_SID set -> Twilio Verify sends and checks the
//           code itself (no phone number needed, works worldwide).
//   sms     a sender is set (TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM) ->
//           we generate the code and text it through the Messages API.
//   dev     nothing configured, or PHONE_AUTH=dev -> the code is logged and
//           returned to the app as devOtp (test mode).
//
// Attorney details after a booking is accepted go through the Messages API
// with a sender, optionally as a Content Template (TWILIO_ATTORNEY_CONTENT_SID).
import {
  PHONE_AUTH,
  TWILIO_ACCOUNT_SID,
  TWILIO_ATTORNEY_CONTENT_SID,
  TWILIO_AUTH_TOKEN,
  TWILIO_FROM,
  TWILIO_MESSAGING_SERVICE_SID,
  TWILIO_VERIFY_SERVICE_SID,
} from '../config';

const hasAccount = () => TWILIO_ACCOUNT_SID.length > 0 && TWILIO_AUTH_TOKEN.length > 0;

/** A sender for the Messages API (plain texts, attorney details). */
export function isSmsConfigured(): boolean {
  return hasAccount() && (TWILIO_FROM.length > 0 || TWILIO_MESSAGING_SERVICE_SID.length > 0);
}

export function isVerifyConfigured(): boolean {
  return hasAccount() && TWILIO_VERIFY_SERVICE_SID.length > 0;
}

export type OtpMode = 'verify' | 'sms' | 'dev';

export function otpMode(): OtpMode {
  if (PHONE_AUTH === 'dev') return 'dev';
  if (isVerifyConfigured()) return 'verify';
  return isSmsConfigured() ? 'sms' : 'dev';
}

export class SmsError extends Error {
  constructor(message: string, public readonly code?: number) {
    super(message);
  }
}

function authHeader(): string {
  return `Basic ${Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64')}`;
}

async function twilioPost<T>(url: string, params: URLSearchParams): Promise<T> {
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: authHeader(), 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });
  const data = (await res.json().catch(() => ({}))) as T & { message?: string; code?: number };
  if (!res.ok) throw new SmsError(data.message ?? `Twilio error ${res.status}`, data.code);
  return data;
}

// ---------------------------------------------------------------- Verify

/** Twilio Verify: asks Twilio to text a code to `to` (E.164). */
export async function startVerification(to: string): Promise<void> {
  if (!isVerifyConfigured()) throw new SmsError('Twilio Verify is not configured');
  const r = await twilioPost<{ status?: string; sid?: string }>(
    `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}/Verifications`,
    new URLSearchParams({ To: to, Channel: 'sms' }),
  );
  console.log(`[Verify] ${to} -> ${r.status ?? 'pending'} (${r.sid ?? '?'})`);
}

/** Twilio Verify: true when `code` is the one Twilio sent to `to`. */
export async function checkVerification(to: string, code: string): Promise<boolean> {
  if (!isVerifyConfigured()) throw new SmsError('Twilio Verify is not configured');
  try {
    const r = await twilioPost<{ status?: string }>(
      `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}/VerificationCheck`,
      new URLSearchParams({ To: to, Code: code }),
    );
    return r.status === 'approved';
  } catch (err) {
    // 20404 = no pending verification (expired or already used): just wrong.
    if (err instanceof SmsError && err.code === 20404) return false;
    throw err;
  }
}

// -------------------------------------------------------------- Messages

/** Raw Messages call; resolves with the text Twilio actually sent. */
async function postMessage(
  to: string,
  body: string,
  content?: { sid: string; variables: Record<string, string> },
): Promise<{ body: string }> {
  if (!isSmsConfigured()) throw new SmsError('SMS is not configured');
  const params = new URLSearchParams({ To: to });
  if (content) {
    params.set('ContentSid', content.sid);
    params.set('ContentVariables', JSON.stringify(content.variables));
  } else {
    params.set('Body', body);
  }
  if (TWILIO_MESSAGING_SERVICE_SID) params.set('MessagingServiceSid', TWILIO_MESSAGING_SERVICE_SID);
  else params.set('From', TWILIO_FROM);
  const data = await twilioPost<{ sid?: string; status?: string; body?: string }>(
    `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(TWILIO_ACCOUNT_SID)}/Messages.json`,
    params,
  );
  console.log(`[SMS] ${to} -> ${data.status ?? 'queued'} (${data.sid ?? '?'})`);
  return { body: data.body ?? body };
}

/** Sends one plain SMS. Throws SmsError with Twilio's reason on rejection. */
export async function sendSms(to: string, body: string): Promise<void> {
  await postMessage(to, body);
}

/**
 * Sends the login code through the Messages API ("sms" mode). Returns the
 * code the user will actually receive.
 *
 * Twilio trial accounts refuse custom text and only send their own canned
 * templates; the "sms_2fa" one carries a code Twilio picks and echoes back
 * in the API response, so on a trial account we adopt Twilio's code.
 */
export async function sendOtpSms(to: string, otp: string, message: string): Promise<string> {
  try {
    await postMessage(to, message);
    return otp;
  } catch (err) {
    if (!(err instanceof SmsError) || !/predefined SMS templates/i.test(err.message)) throw err;
    const sent = await postMessage(to, 'sms_2fa');
    const code = /(\d{4,8})/.exec(sent.body)?.[1];
    if (!code) throw new SmsError('Twilio trial template did not include a code');
    console.log('[SMS] trial account: using Twilio template code');
    return code;
  }
}

/**
 * Best-effort SMS for non-critical notices: skipped with a log line when no
 * sender is configured, never throws.
 */
export function notifySms(to: string, body: string): void {
  if (!isSmsConfigured()) {
    console.log(`[SMS skipped, no Twilio sender] ${to}: ${body}`);
    return;
  }
  sendSms(to, body).catch((err) => {
    console.error(`[SMS] to ${to} failed: ${err instanceof Error ? err.message : err}`);
  });
}

export interface AttorneyDetailsSms {
  attorney: string;
  date: string;
  time: string;
  contact: string;
}

/**
 * "Your consultation was accepted" text with the attorney's contact. Uses
 * the Content Template TWILIO_ATTORNEY_CONTENT_SID when set (variables
 * {{1}} attorney, {{2}} date, {{3}} time, {{4}} contact), else plain text.
 * Best-effort like notifySms.
 */
export function notifyAttorneyDetails(to: string, d: AttorneyDetailsSms): void {
  const text = `ADVOK: ${d.attorney} accepted your consultation on ${d.date} at ${d.time}. Contact: ${d.contact}.`;
  if (!isSmsConfigured()) {
    console.log(`[SMS skipped, no Twilio sender] ${to}: ${text}`);
    return;
  }
  const content = TWILIO_ATTORNEY_CONTENT_SID
    ? { sid: TWILIO_ATTORNEY_CONTENT_SID, variables: { '1': d.attorney, '2': d.date, '3': d.time, '4': d.contact } }
    : undefined;
  postMessage(to, text, content).catch((err) => {
    console.error(`[SMS] attorney details to ${to} failed: ${err instanceof Error ? err.message : err}`);
  });
}

/** E.164 from the app's separate dial code + local number, e.g. +1 / 9412340527. */
export function toE164(countryCode: string, phone: string): string {
  const digits = phone.replace(/\D/g, '');
  const cc = countryCode.replace(/\D/g, '');
  return `+${cc}${digits}`;
}
