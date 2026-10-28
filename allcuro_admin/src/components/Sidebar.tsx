import React from 'react';
import {
  LayoutDashboard,
  ShieldCheck,
  Activity,
  Building2,
  DollarSign,
  AlertTriangle,
  BarChart3,
  ClipboardList,
  LifeBuoy,
  FileSpreadsheet,
  FolderKanban,
  PanelLeftClose,
  PanelLeftOpen,
} from 'lucide-react';
import type { NavSection } from '../types/admin';

interface SidebarProps {
  currentSection: NavSection;
  onSelectSection: (section: NavSection) => void;
  pendingVerifications: number;
  sosAlertsCount: number;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentSection,
  onSelectSection,
  pendingVerifications,
  sosAlertsCount,
  isCollapsed,
  onToggleCollapse,
}) => {
  return (
    <aside className={`allcuro-single-sidebar ${isCollapsed ? 'collapsed' : 'expanded'}`}>
      {/* Brand Header */}
      <div className="sidebar-brand-row">
        <div className="brand-logo-icon">
          <span className="brand-logo-text">C</span>
        </div>
        {!isCollapsed && (
          <div className="brand-text-block">
            <span className="brand-app-name">allcuro.care</span>
            <span className="brand-badge-sub">Control HQ</span>
          </div>
        )}
      </div>

      {/* Navigation Menu */}
      <div className="sidebar-menu-scrollable">
        {!isCollapsed && <div className="nav-group-title">MAIN DASHBOARDS</div>}

        <nav className="nav-menu-list">
          <button
            className={`nav-menu-item ${currentSection === 'overview' ? 'active' : ''}`}
            onClick={() => onSelectSection('overview')}
            title={isCollapsed ? 'Marketplace Overview' : undefined}
          >
            <LayoutDashboard size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Marketplace Overview</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'verification' ? 'active' : ''}`}
            onClick={() => onSelectSection('verification')}
            title={isCollapsed ? `KYC Verification (${pendingVerifications})` : undefined}
          >
            <ShieldCheck size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Verification Queue</span>}
            {pendingVerifications > 0 && (
              <span className={`pill-badge ${isCollapsed ? 'dot-badge' : ''}`}>
                {isCollapsed ? '' : pendingVerifications}
              </span>
            )}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'live_ops' ? 'active' : ''}`}
            onClick={() => onSelectSection('live_ops')}
            title={isCollapsed ? 'Live Shifts & SOS' : undefined}
          >
            <Activity size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Live Shifts & SOS</span>}
            {sosAlertsCount > 0 && (
              <span className={`pill-badge alert-badge ${isCollapsed ? 'dot-badge red' : ''}`}>
                {isCollapsed ? '' : `${sosAlertsCount} SOS`}
              </span>
            )}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'centres_beds' ? 'active' : ''}`}
            onClick={() => onSelectSection('centres_beds')}
            title={isCollapsed ? 'Care Centres & Beds' : undefined}
          >
            <Building2 size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Care Centres & Beds</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'payouts' ? 'active' : ''}`}
            onClick={() => onSelectSection('payouts')}
            title={isCollapsed ? 'Razorpay Split Ledger' : undefined}
          >
            <DollarSign size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Razorpay Split Ledger</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'compliance' ? 'active' : ''}`}
            onClick={() => onSelectSection('compliance')}
            title={isCollapsed ? 'Compliance & Licenses' : undefined}
          >
            <AlertTriangle size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Compliance & Licenses</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'analytics' ? 'active' : ''}`}
            onClick={() => onSelectSection('analytics')}
            title={isCollapsed ? 'City Demand Heatmap' : undefined}
          >
            <BarChart3 size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Demand Heatmap</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'services' ? 'active' : ''}`}
            onClick={() => onSelectSection('services')}
            title={isCollapsed ? 'Services Catalog' : undefined}
          >
            <ClipboardList size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Services Catalog</span>}
          </button>
        </nav>

        {!isCollapsed && <div className="nav-group-title" style={{ marginTop: '20px' }}>REPORTS & AUDITS</div>}

        <div className="nav-menu-list">
          <div className="nav-menu-item secondary" title={isCollapsed ? 'GST Settlement Ledger' : undefined}>
            <FileSpreadsheet size={17} className="item-icon" />
            {!isCollapsed && <span className="item-label">GST Settlements</span>}
          </div>
          <div className="nav-menu-item secondary" title={isCollapsed ? 'Field Audit Logs (7)' : undefined}>
            <FolderKanban size={17} className="item-icon" />
            {!isCollapsed && <span className="item-label">Field Audit Logs</span>}
            {!isCollapsed && <span className="pill-badge pink-badge">7</span>}
          </div>
        </div>
      </div>

      {/* Footer Support & Collapse Toggle */}
      <div className="sidebar-footer-row">
        <button
          className={`nav-menu-item ${currentSection === 'support' ? 'active' : ''}`}
          onClick={() => onSelectSection('support')}
          title={isCollapsed ? 'Ops Helpdesk' : undefined}
        >
          <LifeBuoy size={18} className="item-icon" />
          {!isCollapsed && <span className="item-label">Ops Helpdesk</span>}
        </button>

        <button
          className="collapse-toggle-btn"
          onClick={onToggleCollapse}
          title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {isCollapsed ? <PanelLeftOpen size={18} /> : <PanelLeftClose size={18} />}
          {!isCollapsed && <span style={{ marginLeft: '8px' }}>Collapse Sidebar</span>}
        </button>
      </div>
    </aside>
  );
};
