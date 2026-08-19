import type { CmsPage } from './cms.model';

/**
 * Default app pages, seeded once into the DB. Content matches what the app
 * used to hardcode, so nothing changes until an admin edits it.
 */
export const DEFAULT_CMS_PAGES: CmsPage[] = [
  {
    slug: 'terms-and-conditions',
    title: 'Terms & Conditions',
    sections: [
      {
        title: '1. Acceptance of Terms',
        body: 'By accessing or using ADVOK, you agree to be bound by these Terms and our Privacy Policy.',
      },
      {
        title: '2. Use of Services',
        body: 'ADVOK provides a platform connecting clients with legal professionals. We are not a law firm and do not provide legal advice.',
      },
      {
        title: '3. User Accounts',
        body: 'You are responsible for maintaining the confidentiality of your account credentials.',
      },
      {
        title: '4. Advocate Verification',
        body: 'All advocates listed on ADVOK are independently verified against Bar Council records.',
      },
      {
        title: '5. Payment & Refunds',
        body: 'Consultation fees are charged at the rates listed by each advocate. Refunds are available within 24 hours of booking if cancelled before the consultation begins.',
      },
      {
        title: '6. Prohibited Conduct',
        body: 'You may not use ADVOK for any unlawful purpose or to harass advocates or other users.',
      },
      {
        title: '7. Governing Law',
        body: 'These Terms shall be governed by the laws of India.',
      },
    ],
    lastUpdatedLabel: 'Effective: January 1, 2025',
    updatedAt: '2025-01-01T00:00:00.000Z',
  },
  {
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    sections: [
      {
        title: '1. Information We Collect',
        body: 'We collect information you provide directly to us, such as when you create an account, fill in a form, make a booking, send us a message, or otherwise communicate with us.',
      },
      {
        title: '2. How We Use Your Information',
        body: 'We use the information we collect to operate and improve our services, process bookings, send you technical notices and support messages, respond to comments, and monitor usage.',
      },
      {
        title: '3. Information Sharing',
        body: 'We do not sell your personal data. We may share your information with service providers who assist us in operating the platform.',
      },
      {
        title: '4. Data Security',
        body: 'We take reasonable measures to help protect information about you from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
      },
      {
        title: '5. Your Rights',
        body: 'You have the right to access, update, or delete your personal information at any time from your profile settings.',
      },
      {
        title: '6. Contact',
        body: 'If you have any questions about this Privacy Policy, please contact us at privacy@advok.app.',
      },
    ],
    lastUpdatedLabel: 'Last updated: January 1, 2025',
    updatedAt: '2025-01-01T00:00:00.000Z',
  },
  {
    slug: 'about-us',
    title: 'About ADVOK',
    sections: [
      {
        title: 'Who We Are',
        body: 'ADVOK is a platform that connects clients with verified advocates, law firms, and legal resources across India.',
      },
      {
        title: 'Our Mission',
        body: 'To make quality legal help accessible, transparent, and affordable for everyone.',
      },
    ],
    lastUpdatedLabel: 'Last updated: January 1, 2025',
    updatedAt: '2025-01-01T00:00:00.000Z',
  },
];
