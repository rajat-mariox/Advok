import { useEffect, useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  IconBell,
  IconBook,
  IconBriefcase,
  IconBuilding,
  IconCalendar,
  IconChat,
  IconDollar,
  IconFile,
  IconGraduation,
  IconHome,
  IconLogout,
  IconScale,
  IconSearch,
  IconSettings,
  IconSparkle,
  IconUserCheck,
  IconUsers,
} from '../components/Icon';
import { Avatar } from '../components/ui';
import { authFetch, logout } from '../utils/auth';

interface PendingCounts {
  advocate: number;
  law_student: number;
  law_firm: number;
  total: number;
}

const EMPTY_COUNTS: PendingCounts = { advocate: 0, law_student: 0, law_firm: 0, total: 0 };

function Item({
  to,
  icon,
  label,
  count,
}: {
  to: string;
  icon: React.ReactNode;
  label: string;
  count?: number;
}) {
  return (
    <NavLink to={to} end={to === '/'} className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
      {icon} {label}
      {count !== undefined && count > 0 && <span className="nav-count">{count}</span>}
    </NavLink>
  );
}

export default function AdminLayout() {
  const navigate = useNavigate();
  const [counts, setCounts] = useState<PendingCounts>(EMPTY_COUNTS);

  useEffect(() => {
    authFetch('/admin/registrations/counts')
      .then(async (res) => {
        if (res.ok) setCounts(await res.json());
      })
      .catch(() => {});
  }, []);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <div className="logo-mark">A</div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 800, letterSpacing: -0.3 }}>ADVOK</div>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.4, color: 'var(--text-grey)' }}>
              ADMIN PANEL
            </div>
          </div>
        </div>

        <div className="nav-group-label">Overview</div>
        <Item to="/" icon={<IconHome />} label="Dashboard" />
        <Item to="/approvals" icon={<IconUserCheck />} label="Approvals" count={counts.total} />

        <div className="nav-group-label">Users</div>
        <Item to="/advocates" icon={<IconScale />} label="Advocates" count={counts.advocate} />
        <Item to="/clients" icon={<IconUsers />} label="Clients" />
        <Item to="/law-students" icon={<IconGraduation />} label="Law Students" count={counts.law_student} />
        <Item to="/law-firms" icon={<IconBuilding />} label="Law Firms" count={counts.law_firm} />

        <div className="nav-group-label">Operations</div>
        <Item to="/bookings" icon={<IconCalendar />} label="Bookings" />
        <Item to="/cases" icon={<IconBriefcase />} label="Cases" />
        <Item to="/mentorships" icon={<IconUserCheck />} label="Mentorships" />
        <Item to="/legal-queries" icon={<IconChat />} label="Legal Queries" />
        <Item to="/revenue" icon={<IconDollar />} label="Revenue" />

        <div className="nav-group-label">Content</div>
        <Item to="/content" icon={<IconBook />} label="Learning Content" />
        <Item to="/cms" icon={<IconFile />} label="CMS" />
        <Item to="/advok-ai" icon={<IconSparkle />} label="ADVOK AI" />

        <div className="nav-group-label">System</div>
        <Item to="/settings" icon={<IconSettings />} label="Settings" />

        <div style={{ marginTop: 'auto', paddingTop: 16 }}>
          <button
            className="nav-item"
            style={{ width: '100%', color: 'var(--dark-1a)' }}
            onClick={() => {
              logout();
              navigate('/login', { replace: true });
            }}
          >
            <IconLogout /> Logout
          </button>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="search-wrap" style={{ width: 340 }}>
            <IconSearch />
            <input className="input" placeholder="Search users, bookings, cases..." style={{ height: 40 }} />
          </div>
          <div style={{ marginLeft: 'auto' }} className="row">
            <button
              className="close-circle"
              aria-label="Notifications"
              style={{ position: 'relative', background: 'var(--fill-grey)' }}
            >
              <IconBell />
              <span
                style={{
                  position: 'absolute',
                  top: 6,
                  right: 7,
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  background: 'var(--dark-1a)',
                  border: '1.4px solid var(--white)',
                }}
              />
            </button>
          </div>
          <div className="row" style={{ gap: 10 }}>
            <Avatar name="Admin User" size={34} />
            <div>
              <div style={{ fontSize: 12.5, fontWeight: 700 }}>Admin</div>
              <div style={{ fontSize: 10.5, fontWeight: 500, color: 'var(--text-grey)' }}>
                admin@advok.com
              </div>
            </div>
          </div>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
