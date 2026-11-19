import React from 'react';
import { Activity } from 'lucide-react';
import { EmptyState } from './EmptyState';

// Live shifts, GPS check-ins and SOS alerts need a bookings backend, which
// doesn't exist yet. Until then this is an honest empty state.

export const LiveOperationsView: React.FC = () => (
  <div className="live-ops-layout">
    <div className="view-header-row">
      <div>
        <h1 className="view-title">Live Shifts &amp; SOS</h1>
        <p className="view-subtitle">Active in-home care shifts, check-ins and emergency alerts.</p>
      </div>
    </div>

    <EmptyState
      icon={Activity}
      title="No live shifts yet"
      willShow={[
        'Every booked visit or shift that is en route or on duty',
        'Partner check-in / check-out times',
        'SOS alerts raised from the partner or customer app, with one-tap call',
      ]}
    >
      This fills in automatically once families start booking nurses, doctors, physios and caregivers.
    </EmptyState>
  </div>
);
