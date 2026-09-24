// Email notifications over SMTP. One integration that works with AWS SES,
// SendGrid, Mailgun, Gmail/Workspace or any SMTP provider — set SMTP_* and
// MAIL_FROM in backend/.env. Without SMTP_HOST, email is skipped.
import type { Transporter } from 'nodemailer';
import {
  APP_NAME,
  MAIL_FROM,
  SMTP_HOST,
  SMTP_PASS,
  SMTP_PORT,
  SMTP_SECURE,
  SMTP_USER,
} from '../config';
import type {
  AdvocateProfile,
  ClientProfile,
  LawFirmProfile,
  LawStudentProfile,
  NotificationType,
  User,
} from '../models';

let transporter: Transporter | null = null;
let initTried = false;

export function isEmailConfigured(): boolean {
  return SMTP_HOST.length > 0 && MAIL_FROM.length > 0;
}

async function getTransporter(): Promise<Transporter | null> {
  if (transporter || initTried) return transporter;
  initTried = true;
  if (!isEmailConfigured()) return null;
  const nodemailer = await import('nodemailer');
  transporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_SECURE,
    auth: SMTP_USER ? { user: SMTP_USER, pass: SMTP_PASS } : undefined,
  });
  console.log(`Email notifications: SMTP ${SMTP_HOST}:${SMTP_PORT}`);
  return transporter;
}

/** Best email we have for a user (login email, else the profile's). */
export function emailOf(user: User): string | undefined {
  const p = user.profile as
    | (AdvocateProfile & ClientProfile & LawStudentProfile & LawFirmProfile)
    | undefined;
  const candidates = [user.email, p?.professional?.email, p?.email, p?.officialEmail];
  return candidates.find((e): e is string => typeof e === 'string' && e.includes('@'));
}

/** Notification types worth an email (others stay in-app / push only). */
const EMAIL_TYPES: NotificationType[] = [
  'booking_request',
  'booking_accepted',
  'booking_declined',
  'case_assigned',
  'support_reply',
  'query_answered',
  'account_update',
];

export function shouldEmail(type: NotificationType): boolean {
  return EMAIL_TYPES.includes(type);
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

/** Sends one plain notification email. Fire-and-forget; never throws. */
export function sendEmail(to: string, subject: string, body: string): void {
  void (async () => {
    const t = await getTransporter();
    if (!t) return;
    try {
      await t.sendMail({
        from: MAIL_FROM,
        to,
        subject: `${subject} · ${APP_NAME}`,
        text: `${body}\n\nOpen the ${APP_NAME} app for details.\n\nYou receive this because you have an ${APP_NAME} account.`,
        html: `<div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:520px;margin:auto;padding:24px;color:#0a0a0a">
  <div style="font-size:18px;font-weight:800;margin-bottom:12px">${escapeHtml(APP_NAME)}</div>
  <div style="font-size:16px;font-weight:700;margin-bottom:8px">${escapeHtml(subject)}</div>
  <div style="font-size:14px;line-height:1.6;color:#333">${escapeHtml(body)}</div>
  <div style="font-size:13px;color:#777;margin-top:20px">Open the ${escapeHtml(APP_NAME)} app for details.</div>
</div>`,
      });
    } catch (err) {
      console.error('Email send failed:', err instanceof Error ? err.message : err);
    }
  })();
}
