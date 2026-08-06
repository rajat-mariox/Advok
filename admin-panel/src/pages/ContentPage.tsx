import { useState } from 'react';
import { IconBook, IconFile } from '../components/Icon';
import { Badge, FilterChips, PageHeader, StatCard } from '../components/ui';
import { caseStudies, newsArticles } from '../utils/seed';

const TABS = ['Case Studies', 'Legal News'];

export default function ContentPage() {
  const [tab, setTab] = useState('Case Studies');

  const publishedStudies = caseStudies.filter((c) => c.status === 'Published').length;
  const publishedNews = newsArticles.filter((n) => n.status === 'Published').length;
  const totalReads = caseStudies.reduce((sum, c) => sum + c.reads, 0);

  return (
    <div>
      <PageHeader
        eyebrow="Content"
        title="Learning Content"
        subtitle="Case studies and legal news shown to law students in the app."
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconBook />} value={String(caseStudies.length)} label="Case Studies" trend={`${publishedStudies} published`} />
        <StatCard icon={<IconFile />} value={String(newsArticles.length)} label="News Articles" trend={`${publishedNews} published · updated daily`} />
        <StatCard icon={<IconBook />} value={totalReads.toLocaleString('en-US')} label="Total Case Reads" trend="Across all students" />
      </div>

      <div style={{ marginBottom: 16 }}>
        <FilterChips options={TABS} active={tab} onChange={setTab} />
      </div>

      {tab === 'Case Studies' ? (
        <div className="table-card">
          <table className="data">
            <thead>
              <tr>
                <th>Case Study</th>
                <th>Court · Year</th>
                <th>Tag</th>
                <th>Level</th>
                <th>Read Time</th>
                <th>Reads</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {caseStudies.map((c) => (
                <tr key={c.id}>
                  <td>
                    <span className="cell-strong">{c.title}</span>
                  </td>
                  <td>{c.meta}</td>
                  <td>{c.tag}</td>
                  <td>
                    <Badge label={c.level} />
                  </td>
                  <td>{c.mins} min</td>
                  <td>{c.reads > 0 ? c.reads.toLocaleString('en-US') : '—'}</td>
                  <td>
                    <Badge label={c.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="table-card">
          <table className="data">
            <thead>
              <tr>
                <th style={{ width: '46%' }}>Article</th>
                <th>Source</th>
                <th>Tag</th>
                <th>Published</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {newsArticles.map((n) => (
                <tr key={n.id}>
                  <td>
                    <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
                      {n.title}
                    </div>
                  </td>
                  <td>{n.source}</td>
                  <td>{n.tag}</td>
                  <td>{n.time}</td>
                  <td>
                    <Badge label={n.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
