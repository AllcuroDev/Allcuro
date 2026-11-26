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
  Package,
  Pill,
  FileText,
  TicketPercent,
} from 'lucide-react';
import type { NavSection } from '../types/admin';

interface SidebarProps {
  currentSection: NavSection;
  onSelectSection: (section: NavSection) => void;
  pendingVerifications: number;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentSection,
  onSelectSection,
  pendingVerifications,
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
            title={isCollapsed ? `Partners & Approvals (${pendingVerifications})` : undefined}
          >
            <ShieldCheck size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Partners &amp; Approvals</span>}
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
            title={isCollapsed ? 'Payouts Ledger' : undefined}
          >
            <DollarSign size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Payouts Ledger</span>}
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
            title={isCollapsed ? 'Cities & Demand' : undefined}
          >
            <BarChart3 size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Cities &amp; Demand</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'services' ? 'active' : ''}`}
            onClick={() => onSelectSection('services')}
            title={isCollapsed ? 'Services Catalog' : undefined}
          >
            <ClipboardList size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Services Catalog</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'equipment' ? 'active' : ''}`}
            onClick={() => onSelectSection('equipment')}
            title={isCollapsed ? 'Equipment' : undefined}
          >
            <Package size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Equipment</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'medicines' ? 'active' : ''}`}
            onClick={() => onSelectSection('medicines')}
            title={isCollapsed ? 'Medicines' : undefined}
          >
            <Pill size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Medicines</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'coupons' ? 'active' : ''}`}
            onClick={() => onSelectSection('coupons')}
            title={isCollapsed ? 'Coupons & Discounts' : undefined}
          >
            <TicketPercent size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Coupons &amp; Discounts</span>}
          </button>

          <button
            className={`nav-menu-item ${currentSection === 'content' ? 'active' : ''}`}
            onClick={() => onSelectSection('content')}
            title={isCollapsed ? 'Site Content' : undefined}
          >
            <FileText size={18} className="item-icon" />
            {!isCollapsed && <span className="item-label">Site Content &amp; FAQs</span>}
          </button>
        </nav>

        {!isCollapsed && <div className="nav-group-title" style={{ marginTop: '20px' }}>REPORTS & AUDITS</div>}

        <div className="nav-menu-list">
          <div className="nav-menu-item secondary" title={isCollapsed ? 'GST Settlement Ledger' : undefined}>
            <FileSpreadsheet size={17} className="item-icon" />
            {!isCollapsed && <span className="item-label">GST Settlements</span>}
          </div>
          <div className="nav-menu-item secondary" title={isCollapsed ? 'Field Audit Logs' : undefined}>
            <FolderKanban size={17} className="item-icon" />
            {!isCollapsed && <span className="item-label">Field Audit Logs</span>}
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
