import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/Screens/Screens/AdvocateCasesScreen/advocate_cases_screen.dart';
import 'package:advok_app/Screens/Screens/AdvocateClientsScreen/advocate_clients_screen.dart';

void main() {
  test('client relationship maps from the /clients response', () {
    final client = AdvocateClient.fromApi({
      'clientId': 'c1',
      'clientName': 'David Park',
      'clientPhoto': null,
      'since': '2026-08-20T10:00:00.000Z',
      'consultationType': 'video_call',
      'openCases': 0,
      'sessions': 1,
    });

    expect(client.id, 'c1');
    expect(client.name, 'David Park');
    expect(client.matter, 'Video consultation');
    expect(client.joined, 'Aug 20');
    expect(client.sessions, 1);
  });

  test('open cases take over the client matter line', () {
    final client = AdvocateClient.fromApi({
      'clientId': 'c2',
      'clientName': 'Alex Thompson',
      'since': '2026-08-01T10:00:00.000Z',
      'consultationType': 'office_visit',
      'openCases': 2,
      'sessions': 3,
    });

    expect(client.matter, '2 open cases');
    expect(client.openCases, 2);
  });

  test('case maps from the /cases response', () {
    final record = AdvocateCase.fromApi({
      'id': 'k1',
      'caseNumber': '1:24-cv-01234',
      'title': 'Smith v. Jones',
      'clientName': 'David Park',
      'advocateName': 'Sarah Mitchell',
      'status': 'discovery',
      'priority': 'high',
      'filedDate': '2026-07-04',
      'nextHearing': '2026-09-15',
      'practiceArea': 'Civil Litigation',
      'court': 'U.S. District Court',
      'createdAt': '2026-07-04T09:00:00.000Z',
      'timeline': [
        {
          'title': 'Case created on ADVOK',
          'date': '2026-07-04',
          'source': 'attorney',
        },
        {
          'title': 'Docket entry: motion filed',
          'date': '2026-08-01',
          'source': 'court_api',
        },
      ],
    });

    expect(record.id, 'k1');
    expect(record.number, '1:24-cv-01234');
    expect(record.status, CaseStatus.discovery);
    expect(record.priority, CasePriority.high);
    expect(record.filed, 'Jul 4, 2026');
    expect(record.nextHearing, 'Sep 15, 2026');
    expect(record.client, 'David Park');
    expect(record.advocateName, 'Sarah Mitchell');
    expect(record.timeline.length, 2);
    expect(record.timeline.first.fromCourtApi, isFalse);
    expect(record.timeline.last.fromCourtApi, isTrue);
    expect(record.timeline.last.date, 'Aug 1, 2026');
  });

  test('case falls back to createdAt and defaults when fields are missing',
      () {
    final record = AdvocateCase.fromApi({
      'id': 'k2',
      'caseNumber': 'F-08841-26',
      'title': 'Custody Modification',
      'clientName': 'Maria Lopez',
      'status': 'active',
      'court': 'Family Court',
      'createdAt': '2026-08-24T12:00:00.000Z',
    });

    expect(record.status, CaseStatus.active);
    expect(record.priority, isNull);
    expect(record.nextHearing, isNull);
    expect(record.practiceArea, 'General Practice');
    expect(record.filed, 'Aug 24, 2026');
    expect(record.timeline, isEmpty);
  });
}
