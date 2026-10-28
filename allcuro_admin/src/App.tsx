import { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { OverviewView } from './components/OverviewView';
import { VerificationQueueView } from './components/VerificationQueueView';
import { LiveOperationsView } from './components/LiveOperationsView';
import { BedOccupancyView } from './components/BedOccupancyView';
import { PayoutsLedgerView } from './components/PayoutsLedgerView';
import { ComplianceView } from './components/ComplianceView';
import { AnalyticsView } from './components/AnalyticsView';
import { ServicesCatalogView } from './components/ServicesCatalogView';
import { AdminLogin } from './components/AdminLogin';
import { useAdminSession } from './lib/adminAuth';
import type { NavSection } from './types/admin';
import { mockStats } from './data/mockData';
import './App.css';

export function App() {
  const { status, session, signOut } = useAdminSession();
  const [currentSection, setCurrentSection] = useState<NavSection>('overview');
  const [timeframe, setTimeframe] = useState<string>('Sep 1 – Nov 30, 2026');
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);

  const renderCurrentView = () => {
    switch (currentSection) {
      case 'overview':
        return <OverviewView />;
      case 'verification':
        return <VerificationQueueView />;
      case 'live_ops':
        return <LiveOperationsView />;
      case 'centres_beds':
        return <BedOccupancyView />;
      case 'payouts':
        return <PayoutsLedgerView />;
      case 'compliance':
        return <ComplianceView />;
      case 'analytics':
        return <AnalyticsView />;
      case 'services':
        return <ServicesCatalogView />;
      case 'support':
        return <LiveOperationsView />;
      default:
        return <OverviewView />;
    }
  };

  if (status !== 'admin') {
    return <AdminLogin status={status} email={session?.user.email} onSignOut={signOut} />;
  }

  return (
    <div className="allcuro-admin-app-root">
      {/* Single Collapsible Left Sidebar */}
      <Sidebar
        currentSection={currentSection}
        onSelectSection={(sec) => setCurrentSection(sec)}
        pendingVerifications={mockStats.pendingVerifications}
        sosAlertsCount={mockStats.sosAlertsCount}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed((prev) => !prev)}
      />

      {/* Main Content Area */}
      <main className="allcuro-main-content">
        <Header
          timeframe={timeframe}
          setTimeframe={setTimeframe}
          onNewAction={() => setCurrentSection('verification')}
          adminEmail={session?.user.email ?? ''}
          onSignOut={signOut}
        />

        <div className="allcuro-view-viewport">
          {renderCurrentView()}
        </div>
      </main>
    </div>
  );
}

export default App;
