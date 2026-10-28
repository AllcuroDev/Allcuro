import React from 'react';
import {
  Search,
  SlidersHorizontal,
  Download,
  Share2,
  Plus,
  Calendar,
  LogOut,
} from 'lucide-react';

interface HeaderProps {
  timeframe: string;
  setTimeframe: (val: string) => void;
  onNewAction: () => void;
  adminEmail: string;
  onSignOut: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  timeframe,
  setTimeframe,
  onNewAction,
  adminEmail,
  onSignOut,
}) => {
  return (
    <header className="allcuro-header">
      {/* Search Bar matching reference */}
      <div className="header-search-wrap">
        <Search size={16} className="search-icon" />
        <input
          type="text"
          placeholder='Try searching "Indiranagar nurses", "expiring fire NOC", "verified beds"...'
          className="search-input"
        />
        <div className="search-shortcut">⌘K</div>
      </div>

      {/* Right Controls & Team Avatars */}
      <div className="header-right-controls">
        {/* Active Admins list */}
        <div className="team-avatars-row">
          <button className="add-avatar-btn" title="Add Admin">
            <Plus size={14} />
          </button>
          <div className="team-avatar-badge" title="Armin A. (Ops Lead)">
            <span className="avatar-circle green-av">AA</span>
            <span className="avatar-name">Armin A.</span>
          </div>
          <div className="team-avatar-badge" title="Eren Y. (Field Manager)">
            <span className="avatar-circle amber-av">EY</span>
            <span className="avatar-name">Eren Y.</span>
          </div>
          <div className="team-avatar-badge" title="Mikasa A. (Compliance)">
            <span className="avatar-circle blue-av">MA</span>
            <span className="avatar-name">Mikasa A.</span>
          </div>
        </div>

        <div className="header-divider" />

        {/* Timeframe selector pill */}
        <div className="timeframe-toggle-pill">
          <Calendar size={14} className="timeframe-icon" />
          <span className="timeframe-label">Timeframe</span>
          <select
            className="timeframe-select"
            value={timeframe}
            onChange={(e) => setTimeframe(e.target.value)}
          >
            <option value="Sep 1 – Nov 30, 2026">Sep 1 – Nov 30, 2026</option>
            <option value="Aug 1 – Aug 31, 2026">Aug 1 – Aug 31, 2026</option>
            <option value="Jul 1 – Jul 31, 2026">Jul 1 – Jul 31, 2026</option>
            <option value="Full Year 2026">Full Year 2026</option>
          </select>
        </div>

        {/* Action Buttons */}
        <div className="header-actions">
          <button className="icon-action-btn" title="Filter metrics">
            <SlidersHorizontal size={16} />
          </button>
          <button className="icon-action-btn" title="Export report (CSV / PDF)">
            <Download size={16} />
          </button>
          <button className="icon-action-btn" title="Share dashboard link">
            <Share2 size={16} />
          </button>
          <button
            className="primary-action-btn"
            onClick={onNewAction}
            title="Create Verification or SOS Dispatch"
          >
            <Plus size={16} />
          </button>
          <button
            className="icon-action-btn"
            onClick={onSignOut}
            title={`Sign out ${adminEmail}`}
            aria-label="Sign out"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </header>
  );
};
