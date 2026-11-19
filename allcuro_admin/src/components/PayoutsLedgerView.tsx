import React from 'react';
import { Wallet } from 'lucide-react';
import { EmptyState } from './EmptyState';

// Razorpay Route split payouts need bookings + payments, which aren't live
// yet. No placeholder totals or transactions.

export const PayoutsLedgerView: React.FC = () => (
  <div className="payouts-ledger-layout">
    <div className="view-header-row">
      <div>
        <h1 className="view-title">Payouts Ledger</h1>
        <p className="view-subtitle">
          Customer payment → Allcuro commission → partner payout, settled through Razorpay Route.
        </p>
      </div>
    </div>

    <EmptyState
      icon={Wallet}
      title="No payments yet"
      willShow={[
        'Gross collections, Allcuro commission and partner payouts',
        'Each booking’s split settlement and its status',
        'Equipment security deposits held and refunded',
        'GST settlement export',
      ]}
    >
      Transactions appear here once online payments for bookings go live. Partner payout accounts are already
      collected during sign-up — see each partner under Partners &amp; Approvals.
    </EmptyState>
  </div>
);
