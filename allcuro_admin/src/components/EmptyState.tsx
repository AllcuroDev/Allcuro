import React from 'react';
import type { LucideIcon } from 'lucide-react';

// Shown where a section has no backend data yet (bookings, shifts, payouts…).
// No placeholder rows or numbers — just what will appear here and when.

interface Props {
  icon: LucideIcon;
  title: string;
  children: React.ReactNode;
  /** What this section will show once data exists. */
  willShow?: string[];
  action?: React.ReactNode;
}

export const EmptyState: React.FC<Props> = ({ icon: Icon, title, children, willShow, action }) => (
  <div className="empty-state-card">
    <span className="empty-state-icon">
      <Icon size={22} />
    </span>
    <h3 className="empty-state-title">{title}</h3>
    <p className="empty-state-text">{children}</p>
    {willShow && willShow.length > 0 && (
      <ul className="empty-state-list">
        {willShow.map((x) => (
          <li key={x}>{x}</li>
        ))}
      </ul>
    )}
    {action && <div className="empty-state-action">{action}</div>}
  </div>
);
