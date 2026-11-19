import React from 'react';
import { ShieldAlert } from 'lucide-react';
import { EmptyState } from './EmptyState';

// Licence / NOC expiry tracking isn't captured in the database yet, so there
// is nothing to alert on. No placeholder alerts.

export const ComplianceView: React.FC = () => (
  <div className="compliance-view-layout">
    <div className="view-header-row">
      <div>
        <h1 className="view-title">Compliance &amp; Licences</h1>
        <p className="view-subtitle">Expiring registrations, licences and re-verification reminders.</p>
      </div>
    </div>

    <EmptyState
      icon={ShieldAlert}
      title="No compliance alerts"
      willShow={[
        'Nursing council registrations and centre licences nearing expiry',
        'Annual re-verification reminders for live partners',
        'Partners automatically paused when a document lapses',
      ]}
    >
      Alerts appear here once partners’ document expiry dates are tracked. Registration and licence numbers
      submitted at sign-up are visible on each partner under Partners &amp; Approvals.
    </EmptyState>
  </div>
);
