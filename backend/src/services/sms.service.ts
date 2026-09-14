// No SMS gateway in this prototype — messages are logged, mirroring the OTP
// flow in auth.controller. Wire a provider here for production (for the US
// market: Twilio with A2P 10DLC registration, or AWS SNS).
export function sendSms(to: string, message: string): void {
  console.log(`[SMS → ${to}] ${message}`);
}
