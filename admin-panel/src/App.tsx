import { HashRouter, Navigate, Route, Routes } from 'react-router-dom';
import AdminLayout from './layouts/AdminLayout';
import AdvocatesPage from './pages/AdvocatesPage';
import ApprovalsPage from './pages/ApprovalsPage';
import AdvokAiPage from './pages/AdvokAiPage';
import BookingsPage from './pages/BookingsPage';
import CasesPage from './pages/CasesPage';
import ClientsPage from './pages/ClientsPage';
import CmsPagesPage from './pages/CmsPagesPage';
import ContentPage from './pages/ContentPage';
import DashboardPage from './pages/DashboardPage';
import LawFirmsPage from './pages/LawFirmsPage';
import LawStudentsPage from './pages/LawStudentsPage';
import LegalQueriesPage from './pages/LegalQueriesPage';
import LoginPage from './pages/LoginPage';
import MentorshipsPage from './pages/MentorshipsPage';
import RevenuePage from './pages/RevenuePage';
import SettingsPage from './pages/SettingsPage';
import { isAuthenticated } from './utils/auth';

function RequireAuth({ children }: { children: React.ReactNode }) {
  if (!isAuthenticated()) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          element={
            <RequireAuth>
              <AdminLayout />
            </RequireAuth>
          }
        >
          <Route path="/" element={<DashboardPage />} />
          <Route path="/approvals" element={<ApprovalsPage />} />
          <Route path="/advocates" element={<AdvocatesPage />} />
          <Route path="/clients" element={<ClientsPage />} />
          <Route path="/law-students" element={<LawStudentsPage />} />
          <Route path="/law-firms" element={<LawFirmsPage />} />
          <Route path="/bookings" element={<BookingsPage />} />
          <Route path="/cases" element={<CasesPage />} />
          <Route path="/mentorships" element={<MentorshipsPage />} />
          <Route path="/legal-queries" element={<LegalQueriesPage />} />
          <Route path="/revenue" element={<RevenuePage />} />
          <Route path="/content" element={<ContentPage />} />
          <Route path="/cms" element={<CmsPagesPage />} />
          <Route path="/advok-ai" element={<AdvokAiPage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Route>
      </Routes>
    </HashRouter>
  );
}
