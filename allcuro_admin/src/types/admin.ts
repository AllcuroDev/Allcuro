export type NavSection =
  | 'overview'
  | 'verification'
  | 'live_ops'
  | 'centres_beds'
  | 'payouts'
  | 'compliance'
  | 'analytics'
  | 'services'
  | 'support';

export interface VerificationItem {
  id: string;
  applicantName: string;
  type: 'Nurse' | 'Home Care Centre' | 'Equipment Vendor';
  category: string;
  appliedDate: string;
  status: 'Pending Review' | 'Site-Visit Scheduled' | 'Verified' | 'Action Required';
  city: string;
  experienceOrBeds: string;
  phone: string;
  email: string;
  documents: {
    name: string;
    type: string;
    status: 'Verified' | 'Under Review' | 'Flagged';
    fileUrl: string;
  }[];
  riskScore: 'Low' | 'Medium' | 'High';
  lastActivity: string;
}

export interface LiveBookingShift {
  id: string;
  patientName: string;
  patientAddress: string;
  serviceType: string;
  providerName: string;
  providerType: 'Nurse' | 'Attendant' | 'Centre Bed';
  shiftTime: string;
  status: 'En-route' | 'On-Duty' | 'Completed' | 'SOS Alert' | 'Needs Reassignment';
  gpsCheckIn: string;
  emergencyContact: string;
  amount: number;
}

export interface BedMatrixCentre {
  id: string;
  name: string;
  locality: string;
  city: string;
  totalBeds: number;
  occupiedBeds: number;
  availableBeds: number;
  staffToPatientRatio: string;
  fireNocExpiry: string;
  biomedicalWasteAuth: boolean;
  fieldAuditStatus: 'Passed' | 'Scheduled' | 'Renewal Due';
  pricePerDay: number;
}

export interface PayoutTransaction {
  id: string;
  bookingId: string;
  customerName: string;
  partnerName: string;
  grossAmount: number;
  allcuroCommission: number;
  partnerPayout: number;
  gatewayFee: number;
  status: 'Settled' | 'Pending Split' | 'On-Hold' | 'Refunded';
  date: string;
  razorpayRouteSubAccount: string;
}

export interface ComplianceAlert {
  id: string;
  providerName: string;
  providerType: 'Nurse' | 'Centre';
  itemTitle: string;
  expiryDate: string;
  daysRemaining: number;
  severity: 'Critical' | 'Warning' | 'Info';
  autoAction: string;
}
