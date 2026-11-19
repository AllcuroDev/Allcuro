import React from 'react';
import {
  Search,
  SlidersHorizontal,
  Download,
  Share2,
  Plus,
  LogOut,
} from 'lucide-react';

interface HeaderProps {
  onNewAction: () => void;
  adminEmail: string;
  onSignOut: () => void;
}

export const Header: React.FC<HeaderProps> = ({
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
          placeholder="Search…"
          className="search-input"
        />
        <div className="search-shortcut">⌘K</div>
      </div>

      {/* Right Controls */}
      <div className="header-right-controls">
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
            title="Partners &amp; Approvals"
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
