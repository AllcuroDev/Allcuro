import { useId, useState } from 'react'
import { Modal } from '../../components/ui'
import { initials, useNow } from '../../lib/format'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { PBody, PCard, PIcon, PPageHead } from '../ui'
import { CHECKLIST_ITEMS, SOS_GPS_VISIT, checklistDone, type NurseVisit } from './data'
import { SosButton } from './parts'
import {
  checkInVisit,
  completeVisitWithOtp,
  formatDuration,
  formatTimer,
  logVitals,
  mapsUrl,
  resetDemoVisit,
  setChecklistItem,
  setVisitStatus,
  telUrl,
  verifyArrivalGpsAndSelfie,
  visitStore,
  visitStatusLabel,
} from './state'

// Active home visit — requests/nurse_visit_execution_screen.dart: GPS +
// selfie arrival check, check-in timer, digital vitals, clinical
// checklist, OTP check-out and SOS.

const statusTone = (v: NurseVisit) => (v.status === 'completed' ? 'is-ok' : v.status === 'inProgress' ? 'is-coral' : 'is-warn')

export function NurseVisitExecutionPage() {
  const visit = visitStore.use()

  return (
    <>
      <PPageHead
        back={PR.nurseHome}
        title={
          <span className="pn-visit-title">
            {visit.bookingId}
            <span className={`pn-status ${statusTone(visit)}`}>{visitStatusLabel[visit.status]}</span>
          </span>
        }
        subtitle={visit.serviceType}
        aside={
          <SosButton
            text="Triggering SOS will broadcast your live GPS location to ALLCURO Emergency Response HQ and dial 24x7 clinical support."
            gps={SOS_GPS_VISIT}
            callLabel="Call Allcuro SOS Desk"
            sentMessage="SOS Alert Dispatched! ALLCURO Team is dialing you."
          />
        }
      />
      <PBody>
        <div className="pn-visit-grid">
          <div className="pn-col">
            <PatientCard visit={visit} />
            <ArrivalCard visit={visit} />
            <TimerCard visit={visit} />
          </div>
          <div className="pn-col">
            <VitalsCard visit={visit} />
            <ChecklistCard visit={visit} />
            <ActionFooter visit={visit} />
          </div>
        </div>
      </PBody>
    </>
  )
}

function PatientCard({ visit }: { visit: NurseVisit }) {
  return (
    <PCard as="section" className="pn-stack">
      <div className="pn-active-body">
        <span className="pn-avatar-md" aria-hidden="true">
          {initials(visit.patientName)}
        </span>
        <div className="p-row-grow">
          <strong className="pn-title pn-lg">
            {visit.patientName} ({visit.patientAge}y, {visit.patientGender})
          </strong>
          <span className="pn-coral pn-small">{visit.medicalCondition}</span>
          <span className="p-muted pn-small">{visit.address}</span>
          <span className="p-muted pn-small">{visit.timing} · Pay {visit.payAmount}</span>
        </div>
      </div>
      {visit.instructions.length > 0 && (
        <div className="pn-instructions">
          <h3 className="pn-overline">Care instructions</h3>
          <ul>
            {visit.instructions.map((i) => (
              <li key={i}>{i}</li>
            ))}
          </ul>
        </div>
      )}
      <hr className="pn-hr" />
      <div className="pn-btn-pair">
        <a
          className="p-btn p-btn-outline pn-btn-primary-text pn-border-primary"
          href={mapsUrl(visit.address)}
          target="_blank"
          rel="noreferrer"
          onClick={() => toast(`Opening Google Maps route to ${visit.address}…`, 'info')}
        >
          <PIcon name="navigate" size={16} /> Google Maps
        </a>
        <a className="p-btn p-btn-primary" href={telUrl(visit.patientPhone)} onClick={() => toast(`Dialing patient family: ${visit.patientPhone}`)}>
          <PIcon name="phone" size={16} /> Call Patient
        </a>
      </div>
    </PCard>
  )
}

function ArrivalCard({ visit }: { visit: NurseVisit }) {
  const [busy, setBusy] = useState(false)
  const isReached = visit.status !== 'assigned' && visit.status !== 'enRoute'
  return (
    <PCard as="section" className="pn-stack">
      <div className="pn-card-head">
        <PIcon name="pin" size={18} />
        <h2>Arrival Verification &amp; GPS Check</h2>
        {isReached && (
          <span className="p-pill is-ok">
            <PIcon name="check" size={12} /> Verified
          </span>
        )}
      </div>
      <div className="pn-badges">
        <VerificationBadge title="GPS Geofence" subtitle={isReached ? 'Within 30m of patient' : 'Required upon arrival'} done={visit.isGpsVerified || isReached} />
        <VerificationBadge title="Selfie Check" subtitle={isReached ? 'Face match passed' : 'Mandatory live check'} done={visit.isSelfieVerified || isReached} />
      </div>
      {visit.status === 'assigned' && (
        <button
          type="button"
          className="p-btn p-btn-outline p-btn-block"
          disabled={busy}
          onClick={async () => {
            setBusy(true)
            await setVisitStatus('enRoute')
            setBusy(false)
            toast('Travel started — the family can now track your arrival.', 'info')
          }}
        >
          <PIcon name="navigate" size={16} /> Start travel to patient
        </button>
      )}
      {!isReached && (
        <button
          type="button"
          className="p-btn p-btn-warm p-btn-block"
          disabled={busy}
          onClick={async () => {
            setBusy(true)
            await verifyArrivalGpsAndSelfie()
            setBusy(false)
            toast('Arrival GPS & Live Selfie Verified! You can now check in.')
          }}
        >
          <PIcon name="camera" size={16} /> {busy ? 'Verifying…' : "I've Reached — Take Selfie & Verify GPS"}
        </button>
      )}
    </PCard>
  )
}

function VerificationBadge({ title, subtitle, done }: { title: string; subtitle: string; done: boolean }) {
  return (
    <div className={`pn-vbadge ${done ? 'is-done' : ''}`}>
      <span className="pn-vbadge-icon" aria-hidden="true">
        {done ? <PIcon name="check" size={14} /> : null}
      </span>
      <span className="pn-ellipsis-col">
        <strong>{title}</strong>
        <span className="pn-ellipsis">{subtitle}</span>
      </span>
      <span className="sr-only">{done ? 'done' : 'pending'}</span>
    </div>
  )
}

function TimerCard({ visit }: { visit: NurseVisit }) {
  const now = useNow(1000)
  const [busy, setBusy] = useState(false)
  const isInProgress = visit.status === 'inProgress'
  const isCompleted = visit.status === 'completed'
  const value = isInProgress
    ? formatTimer(((visit.checkInTime ? now - visit.checkInTime : 0) / 1000) | 0)
    : isCompleted
      ? visit.checkInTime && visit.checkOutTime
        ? formatDuration(visit.checkOutTime - visit.checkInTime)
        : '08 hrs 15 mins'
      : 'Not checked in yet'
  return (
    <PCard as="section" className="pn-rowcard">
      <span className={`pn-square ${isInProgress ? 'is-coral' : ''}`}>
        <PIcon name="clock" size={24} />
      </span>
      <div className="p-row-grow">
        <span className="p-muted pn-small">{isCompleted ? 'Shift Duration' : isInProgress ? 'Clinical Timer Running' : 'Shift Status'}</span>
        <strong className={`pn-timer ${isInProgress ? 'pn-coral' : ''}`} aria-live="off">
          {value}
        </strong>
      </div>
      {visit.status === 'reached' && (
        <button
          type="button"
          className="p-btn p-btn-primary"
          disabled={busy}
          onClick={async () => {
            setBusy(true)
            await checkInVisit()
            setBusy(false)
            toast('Checked-in! Clinical timer has started.')
          }}
        >
          Check In
        </button>
      )}
    </PCard>
  )
}

function VitalsCard({ visit }: { visit: NurseVisit }) {
  const v = visit.vitalsLog
  const [bp, setBp] = useState(v?.bloodPressure ?? '120/80')
  const [pulse, setPulse] = useState(String(v?.pulse ?? 74))
  const [sugar, setSugar] = useState(String(v?.bloodSugar ?? 112))
  const [temp, setTemp] = useState(String(v?.temperature ?? 98.4))
  const [spo2, setSpo2] = useState(String(v?.spO2 ?? 99))
  const [busy, setBusy] = useState(false)

  const save = async () => {
    setBusy(true)
    await logVitals({
      bloodPressure: bp.trim() || '120/80',
      pulse: parseInt(pulse, 10) || 72,
      bloodSugar: parseInt(sugar, 10) || 110,
      temperature: parseFloat(temp) || 98.6,
      spO2: parseInt(spo2, 10) || 99,
      loggedAt: Date.now(),
    })
    setBusy(false)
    toast('Vitals recorded & synced to patient app!')
  }

  const cells: { label: string; value: string; set: (s: string) => void; hint: string; mode: 'numeric' | 'decimal' | 'text' }[] = [
    { label: 'BP (mmHg)', value: bp, set: setBp, hint: '120/80', mode: 'text' },
    { label: 'Pulse (bpm)', value: pulse, set: setPulse, hint: '72', mode: 'numeric' },
    { label: 'Sugar (mg/dL)', value: sugar, set: setSugar, hint: '110', mode: 'numeric' },
    { label: 'Temp (°F)', value: temp, set: setTemp, hint: '98.6', mode: 'decimal' },
    { label: 'SpO2 (%)', value: spo2, set: setSpo2, hint: '99', mode: 'numeric' },
  ]

  return (
    <PCard as="section" className="pn-stack">
      <div className="pn-card-head">
        <span className="pn-coral">
          <PIcon name="heart" size={18} />
        </span>
        <h2>Digital Vitals Logging</h2>
        {v && <span className="p-pill is-ok">Logged</span>}
      </div>
      <div className="pn-vitals">
        {cells.map((c) => (
          <label key={c.label} className="pn-vital">
            <span>{c.label}</span>
            <input value={c.value} placeholder={c.hint} inputMode={c.mode} onChange={(e) => c.set(e.target.value)} />
          </label>
        ))}
        <button type="button" className="p-btn pn-soft-btn" onClick={save} disabled={busy}>
          {busy ? 'Saving…' : 'Save Vitals'}
        </button>
      </div>
      {v && (
        <p className="p-muted pn-small">
          Last logged {new Date(v.loggedAt).toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit' })} · BP {v.bloodPressure} · Pulse {v.pulse} · Sugar{' '}
          {v.bloodSugar} · Temp {v.temperature}°F · SpO2 {v.spO2}%
        </p>
      )}
    </PCard>
  )
}

function ChecklistCard({ visit }: { visit: NurseVisit }) {
  const c = visit.checklist
  return (
    <PCard as="section" className="pn-stack">
      <div className="pn-card-head">
        <h2>Clinical Checklist &amp; Procedures</h2>
        <span className="pn-done-count">
          {checklistDone(c)}/{CHECKLIST_ITEMS.length} Done
        </span>
      </div>
      <ul className="pn-checklist">
        {CHECKLIST_ITEMS.map((item) => (
          <li key={item.key}>
            <label className={c[item.key] ? 'is-done' : ''}>
              <input type="checkbox" checked={c[item.key]} onChange={(e) => setChecklistItem(item.key, e.target.checked)} />
              <span>{item.title}</span>
            </label>
          </li>
        ))}
      </ul>
    </PCard>
  )
}

function ActionFooter({ visit }: { visit: NurseVisit }) {
  const [otpOpen, setOtpOpen] = useState(false)
  if (visit.status === 'completed') {
    return (
      <div className="pn-complete">
        <span className="pn-complete-icon">
          <PIcon name="check" size={20} />
        </span>
        <div className="p-row-grow">
          <strong>Shift Completed Successfully</strong>
          <span className="p-muted pn-small">Payment verified &amp; report filed with Allcuro ops.</span>
        </div>
        <button
          type="button"
          className="p-btn p-btn-ghost p-btn-sm"
          onClick={() => {
            resetDemoVisit()
            toast('Demo visit reset.', 'info')
          }}
        >
          Reset demo
        </button>
      </div>
    )
  }
  return (
    <>
      <button type="button" className="p-btn p-btn-primary p-btn-block pn-big-btn" onClick={() => setOtpOpen(true)} aria-haspopup="dialog">
        <PIcon name="shield" size={18} /> Complete Visit &amp; Enter Patient OTP
      </button>
      {otpOpen && <OtpDialog visit={visit} onClose={() => setOtpOpen(false)} />}
    </>
  )
}

function OtpDialog({ visit, onClose }: { visit: NurseVisit; onClose: () => void }) {
  const id = useId()
  const [otp, setOtp] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    const code = otp.trim()
    if (code.length !== 4) {
      setError('Please enter a 4-digit OTP')
      return
    }
    setBusy(true)
    const ok = await completeVisitWithOtp(code)
    setBusy(false)
    if (ok) {
      onClose()
      toast(`Shift completed! ${visit.payAmount} credited to earnings ledger.`)
    } else {
      setError('Invalid OTP. Please verify with patient.')
    }
  }

  return (
    <Modal onClose={onClose} labelledBy={id} className="pn-modal" dismissable={!busy}>
      <div className="pn-sos-head">
        <span className="pn-circle">
          <PIcon name="shield" size={20} />
        </span>
        <div>
          <h2 id={id}>Complete Visit &amp; Check-Out</h2>
          <p className="p-muted pn-small">Ask the patient / family for their 4-digit completion OTP</p>
        </div>
      </div>
      <div className="pn-gps pn-demo">
        <PIcon name="help" size={18} />
        <span>
          Demo OTP for {visit.patientName}: {visit.expectedOtp}
        </span>
      </div>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          void submit()
        }}
        className="pn-stack"
      >
        <label className="sr-only" htmlFor={`${id}-otp`}>
          Completion OTP
        </label>
        <input
          id={`${id}-otp`}
          className={`pn-otp ${error ? 'has-error' : ''}`}
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={4}
          placeholder="• • • •"
          value={otp}
          autoFocus
          aria-invalid={!!error}
          aria-describedby={error ? `${id}-err` : undefined}
          onChange={(e) => {
            setOtp(e.target.value.replace(/\D/g, '').slice(0, 4))
            setError(null)
          }}
        />
        {error && (
          <span id={`${id}-err`} className="p-field-error" role="alert">
            {error}
          </span>
        )}
        <button type="submit" className="p-btn p-btn-primary p-btn-block" disabled={busy}>
          {busy ? 'Verifying…' : 'Verify OTP & Finalise Shift'}
        </button>
      </form>
    </Modal>
  )
}
