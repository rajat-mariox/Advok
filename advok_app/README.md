# Advok — India and United States market flows

Advok is a legal-services marketplace that connects clients with verified legal professionals, law students, and law firms. The selected country determines the legal terminology, registration requirements, location choices, professional verification, discovery filters, and dashboard language.

This document is a product and operations reference for the two supported legal markets. It contains no implementation instructions.

## Market selection and account entry

Every journey begins with country selection. A user chooses **India** or **United States**, enters a local mobile number, completes one-time-password verification, and then chooses a role.

The chosen market remains attached to the account. Returning users return to the market they registered in, so an India account sees India terminology and a US account sees US terminology.

```text
Open app → Select country → Verify phone number → Choose role
                                                   ├─ Client
                                                   ├─ Legal professional
                                                   ├─ Law student
                                                   └─ Law firm
```

Clients become active immediately. Legal professionals, students, and firms complete registration and wait for an administrator’s decision.

## Shared lifecycle

```text
New account → Role selected → Registration in progress → Submitted for review
                                                              │
                                      ┌───────────────────────┴───────────────────────┐
                                      ↓                                               ↓
                                  Approved                                        Rejected
                                      ↓                                               ↓
                              Relevant dashboard                         Show reason → revise → resubmit
```

While a registration is under review, the user sees a submitted-status screen. Approval makes the profile available in the matching country’s marketplace. A rejected applicant sees the reviewer’s reason and can reapply.

## India market

### Local terminology

| Product concept | India experience |
|---|---|
| Legal professional | Advocate |
| Experience levels | Junior Advocate; Senior Advocate |
| Professional credential | Bar Registration Number |
| Verification source | Bar Council records |
| Junior guidance | Senior Advocate Name is required |
| Location | State, District / City |
| Practice courts | Supreme Court, High Court, District Court, Family Court, Consumer Court, Tribunal |
| Schedule language | Hearings & Tasks |

### India advocate registration

1. The user chooses **Advocate**.
2. In **Describe Yourself**, they choose Junior Advocate or Senior Advocate and identify their purpose for joining.
3. In **Professional Details**, they provide personal and professional information, bar registration number, primary practice court, practice areas, and—when registering as a junior—the required senior advocate’s name.
4. In **Practice Location**, they select an Indian state and enter their district or city. Only the intended public location detail is exposed to clients.
5. In **My Schedule**, they set availability and add hearings or tasks that affect availability.
6. They submit the application for Bar Council-based verification.
7. After approval, the advocate receives the India advocate dashboard and appears to India clients who search matching practice areas and locations.

```text
Choose Advocate → Experience tier → Professional details → India practice location
       → Availability and hearings → Bar Council review → Approved advocate profile
```

### India client journey

1. The client selects **India**, verifies their number, and chooses **Client**.
2. They enter the client home experience immediately.
3. They browse verified advocates, search by name, and filter by practice area, location, court, or advocate tier.
4. They open an advocate profile, review professional details and consultation options, and select a consultation type.
5. They select a date and time, review the booking summary, and confirm the request.
6. Video and phone consultations are confirmed immediately. An office-visit request waits for the advocate to accept or decline.
7. The client tracks, cancels where permitted, or joins the consultation from **Bookings**; messages remain available through **Messages**.

### India law student and firm journeys

- **Law student:** Select Law Student → submit college and identity verification details → administrator review → student dashboard. The approved student can find advocate mentors, send mentorship requests, message professionals, read legal learning content, and participate in legal queries.

- **Law firm:** Select Law Firm → register firm details and India location → add the legal team → administrator review → firm dashboard. An approved firm manages lawyers, client matters, messages, cases, and its firm profile.

## United States market

### Local terminology

| Product concept | United States experience |
|---|---|
| Legal professional | Attorney |
| Professional classification | Years in practice and firm role |
| Firm roles | Partner, Associate, Senior Associate, Of Counsel, Counsel, Staff Attorney, Solo Practitioner |
| Professional credential | State Bar Number and bar-admission status |
| Verification source | State bar records |
| Supervising-attorney field | Optional |
| Location | State, City / County |
| Admissions | State bar admissions plus optional federal court admissions |
| Practice courts | State trial/appellate/supreme courts; federal district/appeals courts; family, bankruptcy, and immigration courts |
| Schedule language | Court Events & Tasks |

### US attorney registration

1. The user chooses **United States** and then **Attorney**.
2. In **Describe Yourself**, they select years in practice and a firm role instead of an India-style junior/senior tier.
3. In **Professional Details**, they enter professional information, practice areas, and one or more state bar admissions. Each admission includes the state, State Bar Number, and license status.
4. They can add applicable federal court admissions. A supervising attorney’s name can be included but is not mandatory.
5. In **Practice Location**, they select a US state and provide their city or county.
6. In **My Schedule**, they set availability and add court events or other tasks.
7. They submit the registration for state-bar verification.
8. When approved, their attorney profile is listed only to US clients and reflects their firm role, admissions, practice areas, and service location.

```text
Choose Attorney → Years in practice + firm role → State bar admissions
       → Optional federal admissions → US location → Court events and availability
       → State bar review → Approved attorney profile
```

### US client journey

1. The client selects **United States**, verifies their number, and chooses **Client**.
2. They browse verified attorneys in the United States marketplace.
3. They search or filter by practice area, state, city/county, attorney firm role, and relevant admissions.
4. They open an attorney profile and choose video, phone, or office consultation where available.
5. They select date and time, review the summary, and place the booking.
6. Video and phone bookings are confirmed immediately; office consultations require the attorney’s acceptance.
7. The client manages the appointment in **Bookings** and contacts the attorney through **Messages**.

### US law student and firm journeys

- **Law student:** Select Law Student → submit school and identity verification details, using US degree wording such as J.D. or LL.M. → administrator review → student dashboard. The student can find attorney mentors, request mentorship, message users, and use learning and legal-query features.

- **Law firm:** Select Law Firm → register firm information and US location → add legal team → administrator review → firm dashboard. The firm can manage attorneys, cases, clients, messages, and its public firm profile.

## Marketplace and booking operations

The marketplace is country-separated: clients see approved legal professionals registered for their own market. Country-specific labels and filters make a profile understandable in its legal context without asking users to translate between systems.

```text
Client home → Find professionals → Search or filter → Profile
    → Consultation type → Date and time → Booking review → Booking created
                                                              ├─ Video / phone: confirmed
                                                              └─ Office visit: attorney or advocate responds
```

For legal professionals, the dashboard surfaces client requests, upcoming consultations, messages, and case-related work. For clients, the dashboard surfaces discovery, bookings, messages, profile management, help, and the Advok AI assistant.

## Roles and access after approval

| Role | India dashboard language | US dashboard language | Main capabilities |
|---|---|---|---|
| Client | Find Advocates | Find Attorneys | Discover, book, message, manage profile |
| Legal professional | Advocate | Attorney | Manage clients, bookings, messages, cases, schedule, profile |
| Law student | Advocate mentors | Attorney mentors | Find mentors, messages, queries, learning content |
| Law firm | Lawyers / advocates | Attorneys | Manage legal team, cases, messages, firm profile |

## Operational review checklist

Administrators review pending submissions against the correct market authority and details before approving a profile.

| India | United States |
|---|---|
| Confirm the advocate’s Bar Registration Number and Bar Council record. | Confirm state bar admission, State Bar Number, and license status. |
| Check the selected practice court, state, and district/city. | Check declared state admissions, optional federal admissions, and state plus city/county location. |
| Confirm the junior advocate’s named senior advocate where applicable. | Review firm role, years in practice, and optional supervising-attorney information. |

Approval unlocks the relevant dashboard and marketplace visibility. A rejection should include a clear reason so the applicant can correct the submission and resubmit.
