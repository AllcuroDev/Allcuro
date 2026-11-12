import { useState } from 'react'
import { Link } from '../../components/Link'
import { toast } from '../../lib/toast'
import { PR } from '../routes'
import { usePartnerSession } from '../session'
import { ChipGroup, PBody, PCard, PIcon, PPageHead, Toggle } from '../ui'
import { CLINICIAN_SKILL_OPTIONS, DAYS, DAY_SLOTS, NURSE_SKILL_OPTIONS, SHIFT_TIME_OPTIONS } from './data'
import {
  addBlockedDate,
  availabilityStore,
  effectiveSkills,
  formatIsoDate,
  removeBlockedDate,
  saveSkillsAndRates,
  setDutyStatus,
  setShiftTiming,
  todayIso,
  toggleDaySlot,
} from './state'

// Duty status & availability — availability/availability_screen.dart, plus
// the skills & shift-rate settings the setup hub's step 5 points at.

export function NurseAvailabilityPage() {
  const a = availabilityStore.use()

  const toggleDuty = async (v: boolean) => {
    await setDutyStatus(v)
    toast(v ? 'You are now ON-DUTY and visible to patients.' : 'You are now OFF-DUTY.', v ? 'success' : 'info')
  }

  return (
    <>
      <PPageHead title="Duty Status & Availability" subtitle="Set your shifts, timing slots and leave days" back={PR.nurseHome} />
      <PBody>
        <div className="pn-two-col">
          <div className="pn-col">
            <PCard as="section" className={`pn-rowcard pn-duty-card ${a.isOnDuty ? 'is-on' : ''}`}>
              <span className="pn-square">
                <PIcon name={a.isOnDuty ? 'bolt' : 'clock'} size={24} />
              </span>
              <div className="p-row-grow">
                <strong className="pn-title">
                  {a.isOnDuty ? 'On-Duty (Available)' : 'Off-Duty (Resting)'} <span className="pn-dot-inline" aria-hidden="true" />
                </strong>
                <span className="p-muted pn-small">
                  {a.isOnDuty ? `Receiving shift requests for: ${a.timing}` : 'Paused. You will not get new urgent requests.'}
                </span>
              </div>
              <Toggle checked={a.isOnDuty} onChange={(v) => void toggleDuty(v)} label="On duty" />
            </PCard>

            <PCard as="section" className="pn-stack">
              <div className="pn-card-head">
                <PIcon name="clock" size={18} />
                <h2 id="pn-timing">Preferred Shift Timing</h2>
              </div>
              <div role="radiogroup" aria-labelledby="pn-timing" className="pn-radios">
                {SHIFT_TIME_OPTIONS.map((opt) => {
                  const on = a.timing === opt
                  return (
                    <button
                      key={opt}
                      type="button"
                      role="radio"
                      aria-checked={on}
                      className={`pn-radio ${on ? 'is-on' : ''}`}
                      onClick={() => {
                        setShiftTiming(opt)
                        void setDutyStatus(a.isOnDuty, opt)
                      }}
                    >
                      <span className="pn-radio-dot" aria-hidden="true" />
                      {opt}
                    </button>
                  )
                })}
              </div>
            </PCard>

            <LeaveDatesCard />
          </div>

          <div className="pn-col">
            <PCard as="section" className="pn-stack">
              <div>
                <h2 className="pn-h2">Weekly Shift Schedule</h2>
                <p className="p-muted pn-small">Tap slots to toggle availability for the upcoming week.</p>
              </div>
              <div className="pn-week">
                {DAYS.map((day) => (
                  <div key={day} className="pn-week-row" role="group" aria-label={day}>
                    <strong>{day}</strong>
                    <div className="pn-slots">
                      {DAY_SLOTS.map((slot) => {
                        const on = a.daySlots.includes(`${day}-${slot}`)
                        return (
                          <button
                            key={slot}
                            type="button"
                            aria-pressed={on}
                            aria-label={`${day} ${slot}`}
                            className={`pn-slot ${on ? 'is-on' : ''}`}
                            onClick={() => toggleDaySlot(day, slot)}
                          >
                            {slot}
                          </button>
                        )
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </PCard>

            <SkillsCard />
          </div>
        </div>
      </PBody>
    </>
  )
}

function LeaveDatesCard() {
  const a = availabilityStore.use()
  const [date, setDate] = useState('')
  const [adding, setAdding] = useState(false)
  return (
    <PCard as="section" className="pn-stack">
      <div className="pn-card-head">
        <h2>Blocked Leave Dates</h2>
        {!adding && (
          <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => setAdding(true)}>
            <PIcon name="plus" size={16} /> Add Date
          </button>
        )}
      </div>
      {adding && (
        <form
          className="pn-inline-form"
          onSubmit={(e) => {
            e.preventDefault()
            if (!date) return
            addBlockedDate(date)
            toast(`${formatIsoDate(date)} blocked as leave.`, 'info')
            setDate('')
            setAdding(false)
          }}
        >
          <label className="sr-only" htmlFor="pn-leave">
            Leave date
          </label>
          <input id="pn-leave" type="date" className="p-input" min={todayIso()} value={date} onChange={(e) => setDate(e.target.value)} required />
          <button type="submit" className="p-btn p-btn-primary p-btn-sm" disabled={!date}>
            Block
          </button>
          <button type="button" className="p-btn p-btn-ghost p-btn-sm" onClick={() => setAdding(false)}>
            Cancel
          </button>
        </form>
      )}
      {a.blockedDates.length === 0 ? (
        <p className="p-muted pn-small">No leave dates blocked.</p>
      ) : (
        <ul className="pn-datechips">
          {a.blockedDates.map((d) => (
            <li key={d}>
              <span>{formatIsoDate(d)}</span>
              <button type="button" onClick={() => removeBlockedDate(d)} aria-label={`Remove leave on ${formatIsoDate(d)}`}>
                <PIcon name="close" size={14} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </PCard>
  )
}

function SkillsCard() {
  const session = usePartnerSession()
  const a = availabilityStore.use()
  const current = effectiveSkills(a, session)
  const options = session.role === 'clinician' ? CLINICIAN_SKILL_OPTIONS : NURSE_SKILL_OPTIONS
  const allOptions = [...options, ...current.filter((s) => !options.includes(s))]
  const [skills, setSkills] = useState(current)
  const valid = skills.length > 0

  return (
    <PCard as="section" className="pn-stack">
      <div>
        <h2 className="pn-h2">Skills &amp; Specialisations</h2>
        <p className="p-muted pn-small">
          Families are matched to you by these skills. Your rates are set by ALLCURO — see them on your{' '}
          <Link to={PR.publicProfile}>public profile</Link>.
        </p>
      </div>
      <ChipGroup options={allOptions} value={skills} onChange={setSkills} />
      <button
        type="button"
        className="p-btn p-btn-primary"
        disabled={!valid}
        onClick={() => {
          saveSkillsAndRates(skills, a.hourlyRate, a.dailyRate)
          toast(`${skills.length} skills saved`)
        }}
      >
        Save skills
      </button>
      {skills.length === 0 && <span className="p-field-error">Select at least one skill.</span>}
    </PCard>
  )
}
