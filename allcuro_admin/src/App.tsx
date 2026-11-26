import { useEffect, useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { OverviewView } from './components/OverviewView';
import { PartnersView } from './components/PartnersView';
import { EquipmentView } from './components/EquipmentView';
import { MedicinesView } from './components/MedicinesView';
import { CouponsView } from './components/CouponsView';
import { SiteContentView } from './components/SiteContentView';
import { countPendingPartners } from './lib/partners';
import { LiveOperationsView } from './components/LiveOperationsView';
import { BedOccupancyView } from './components/BedOccupancyView';
import { PayoutsLedgerView } from './components/PayoutsLedgerView';
import { ComplianceView } from './components/ComplianceView';
import { AnalyticsView } from './components/AnalyticsView';
import { ServicesCatalogView } from './components/ServicesCatalogView';
import { AdminLogin } from './components/AdminLogin';
import { EmptyState } from './components/EmptyState';
import { LifeBuoy } from 'lucide-react';
import { useAdminSession } from './lib/adminAuth';
import type { NavSection } from './types/admin';
import './App.css';

export function App() {
  const { status, session, signOut } = useAdminSession();
  const [currentSection, setCurrentSection] = useState<NavSection>('overview');
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
  const [pendingPartners, setPendingPartners] = useState(0);

  // Real count of partners waiting for approval (public.partners).
  useEffect(() => {
    if (status === 'admin') void countPendingPartners().then(setPendingPartners);
  }, [status]);

  const renderCurrentView = () => {
    switch (currentSection) {
      case 'overview':
        return <OverviewView onNavigate={setCurrentSection} />;
      case 'verification':
        return <PartnersView onCountChange={setPendingPartners} />;
      case 'equipment':
        return <EquipmentView />;
      case 'medicines':
        return <MedicinesView />;
      case 'coupons':
        return <CouponsView />;
      case 'content':
        return <SiteContentView />;
      case 'live_ops':
        return <LiveOperationsView />;
      case 'centres_beds':
        return <BedOccupancyView onOpenPartners={() => setCurrentSection('verification')} />;
      case 'payouts':
        return <PayoutsLedgerView />;
      case 'compliance':
        return <ComplianceView />;
      case 'analytics':
        return <AnalyticsView />;
      case 'services':
        return <ServicesCatalogView />;
      case 'support':
        return (
          <div>
            <div className="view-header-row">
              <div>
                <h1 className="view-title">Ops Helpdesk</h1>
                <p className="view-subtitle">Support requests from families and partners.</p>
              </div>
            </div>
            <EmptyState icon={LifeBuoy} title="No support requests yet">
              Tickets and call-backs from families and partners will appear here once bookings go live.
            </EmptyState>
          </div>
        );
      default:
        return <OverviewView onNavigate={setCurrentSection} />;
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
        pendingVerifications={pendingPartners}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed((prev) => !prev)}
      />

      {/* Main Content Area */}
      <main className="allcuro-main-content">
        <Header
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
