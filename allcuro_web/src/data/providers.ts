// Nurses, care centres and rentable equipment. Mirrors the app's local data
// sources — keep in sync with:
//   allcuro/lib/features/nurses/data/nurses_service.dart
//   allcuro/lib/features/centres/data/centres_service.dart
//   allcuro/lib/features/equipment/data/equipment_service.dart
import centreImg from '../assets/images/centre-1.jpg'
import eqBedImg from '../assets/images/eq-bed.jpg'
import eqOxygenImg from '../assets/images/eq-oxygen.jpg'
import eqWheelchairImg from '../assets/images/eq-wheelchair.jpg'
import nurse1Img from '../assets/images/nurse-1.jpg'
import nurse2Img from '../assets/images/nurse-2.jpg'

export interface ShiftOption {
  label: string
  price: number
  available: boolean
}

export interface Nurse {
  id: string
  name: string
  photo: string
  allcuroId: string
  level: string
  experience: number
  city: string
  languages: string[]
  tags: string[]
  rating: number
  reviews: number
  highlights: string[]
  shifts: ShiftOption[]
  employment: 'Full-time' | 'Part-time' | 'Live-in'
}

export interface Centre {
  id: string
  name: string
  type: string
  locality: string
  city: string
  photo: string
  photoCount: number
  rating: number
  reviews: number
  since: number
  licence: string
  staffRatio: string
  pricePerDay: number
  pricePerMonth: number
  bedsLeft: number
  services: string[]
  scores: { label: string; value: number }[]
  phone: string
}

export interface Equipment {
  id: string
  name: string
  category: string
  photo: string
  perDay: number
  perMonth: number
  deposit: number
  condition: string
  availableIn: string
}

export const nurses: Nurse[] = [
  {
    id: 'priya-sharma',
    name: 'Priya Sharma',
    photo: nurse1Img,
    allcuroId: 'AC-N-10428',
    level: 'B.Sc Nursing',
    experience: 6,
    city: 'Bengaluru',
    languages: ['English', 'Hindi', 'Kannada'],
    tags: ['Wound & Dressing', 'Injections & IV', 'Catheter Care', 'Diabetic Care', 'Post-Op'],
    rating: 4.9,
    reviews: 212,
    highlights: ['B.Sc Gold Medalist', 'Very punctual', 'Gentle with wound care'],
    shifts: [
      { label: 'Home Visit (1–2 hrs)', price: 600, available: true },
      { label: 'Day Shift (12 hrs)', price: 1600, available: true },
      { label: 'Night Shift (12 hrs)', price: 1800, available: true },
    ],
    employment: 'Full-time',
  },
  {
    id: 'rahul-menon',
    name: 'Rahul Menon',
    photo: nurse2Img,
    allcuroId: 'AC-N-10891',
    level: 'Critical Care Certified',
    experience: 9,
    city: 'Bengaluru',
    languages: ['English', 'Malayalam', 'Tamil', 'Hindi'],
    tags: ['Ventilator', 'Tracheostomy', 'ICU Stepdown', 'Palliative Care', 'Injections & IV'],
    rating: 4.95,
    reviews: 186,
    highlights: ['Ex-Manipal Hospital ICU', 'Handles emergencies calmly', 'Tracheostomy specialist'],
    shifts: [
      { label: '12-Hr ICU Day Shift', price: 2000, available: true },
      { label: '12-Hr ICU Night Shift', price: 2300, available: true },
      { label: '24-Hr Live-in ICU Care', price: 3400, available: true },
    ],
    employment: 'Full-time',
  },
  {
    id: 'rajesh-kumar',
    name: 'Rajesh Kumar',
    photo: nurse2Img,
    allcuroId: 'AC-N-10315',
    level: 'GNM Diploma',
    experience: 7,
    city: 'Bengaluru',
    languages: ['English', 'Hindi', 'Kannada', 'Telugu'],
    tags: ['Injections & IV', 'Wound Dressing', "Catheter & Ryle's", 'Elderly Nursing'],
    rating: 4.85,
    reviews: 142,
    highlights: ['Expert in painless IV cannulation', 'Great bedside manner', 'Police verified'],
    shifts: [
      { label: 'Home Visit (1–2 hrs)', price: 500, available: true },
      { label: 'Day Shift (12 hrs)', price: 1400, available: true },
      { label: 'Night Shift (12 hrs)', price: 1600, available: true },
    ],
    employment: 'Full-time',
  },
  {
    id: 'sunita-verma',
    name: 'Sunita Verma',
    photo: nurse1Img,
    allcuroId: 'AC-N-10552',
    level: 'ANM Midwife',
    experience: 5,
    city: 'Bengaluru',
    languages: ['Hindi', 'English', 'Bengali'],
    tags: ['General Nursing', 'Vitals Check', 'Mother & Baby', 'Injections & IV'],
    rating: 4.88,
    reviews: 98,
    highlights: ['Certified Midwife', 'Excellent baby care skills', 'Patient listener'],
    shifts: [
      { label: 'General Visit (1–2 hrs)', price: 450, available: true },
      { label: 'Maternal Visit (2 hrs)', price: 650, available: true },
      { label: 'Day Shift (12 hrs)', price: 1200, available: true },
    ],
    employment: 'Part-time',
  },
  {
    id: 'ananya-sen',
    name: 'Dr. Ananya Sen (PT)',
    photo: nurse1Img,
    allcuroId: 'AC-PT-20109',
    level: 'BPT Physiotherapist',
    experience: 8,
    city: 'Bengaluru',
    languages: ['English', 'Hindi', 'Kannada', 'Bengali'],
    tags: ['Physiotherapy', 'Post-Stroke Rehab', 'Orthopedic Rehab', 'Elderly Mobility'],
    rating: 4.92,
    reviews: 164,
    highlights: ['Neuro Rehab Specialist', 'Custom exercise regimen', 'Brings portable TENS/IFT'],
    shifts: [
      { label: 'General Rehab Session (45m)', price: 750, available: true },
      { label: 'Neuro / Post-Stroke Session (60m)', price: 1100, available: true },
    ],
    employment: 'Full-time',
  },
  {
    id: 'ramesh-pal',
    name: 'Ramesh Pal',
    photo: nurse2Img,
    allcuroId: 'AC-CG-30241',
    level: 'Certified GDA Attendant',
    experience: 4,
    city: 'Bengaluru',
    languages: ['Hindi', 'Kannada'],
    tags: ['Elderly Care', 'Bed Bath', 'Mobility Support', 'Feeding Assistance', 'Companionship'],
    rating: 4.79,
    reviews: 87,
    highlights: ['Certified by NSDC Healthcare', 'Very strong & supportive for transfers', 'Warm & polite'],
    shifts: [
      { label: '12-Hr Day Attendant Shift', price: 950, available: true },
      { label: '24-Hr Live-in Attendant Shift', price: 1900, available: true },
    ],
    employment: 'Full-time',
  },
]

/** Specialty filters on the nurses list, matched against `level` and `tags` (as in nurses_list_screen.dart). */
export const nurseFilters: { label: string; match: string[] }[] = [
  { label: 'All Nurses', match: [] },
  { label: 'Elderly Care', match: ['Elderly', 'Bed Bath', 'Mobility', 'Attendant'] },
  { label: 'Post-Op Recovery', match: ['Post-Op', 'Wound', 'Injections'] },
  { label: 'ICU / Critical Care', match: ['Critical', 'ICU', 'Ventilator', 'Tracheostomy'] },
  { label: 'Palliative', match: ['Palliative'] },
  { label: 'Pediatric', match: ['Mother & Baby', 'Midwife'] },
]

export const centres: Centre[] = [
  {
    id: 'serene-gardens',
    name: 'Serene Gardens Rehab',
    type: 'Rehab & recovery',
    locality: 'J.P. Nagar, 4th Phase',
    city: 'Bengaluru',
    photo: centreImg,
    photoCount: 12,
    rating: 4.8,
    reviews: 128,
    since: 2018,
    licence: 'KA-HCS-2024/0981',
    staffRatio: '1 : 4',
    pricePerDay: 2400,
    pricePerMonth: 62000,
    bedsLeft: 2,
    services: ['24/7 Nursing', 'Doctor on call', 'Physiotherapy', 'Diabetic meals', 'Ambulance tie-up', 'CCTV monitored'],
    scores: [
      { label: 'Hygiene', value: 4.8 },
      { label: 'Staff behaviour', value: 4.9 },
      { label: 'Medical care', value: 4.7 },
      { label: 'Food', value: 4.5 },
      { label: 'Value for money', value: 4.6 },
    ],
    phone: '+91 80 4120 5500',
  },
  {
    id: 'silver-oaks',
    name: 'Silver Oaks Elder Home',
    type: 'Elderly care',
    locality: 'Hiranandani Gardens, Powai',
    city: 'Mumbai',
    photo: centreImg,
    photoCount: 9,
    rating: 4.6,
    reviews: 84,
    since: 2014,
    licence: 'MH-CEA-2023/4402',
    staffRatio: '1 : 3',
    pricePerDay: 2900,
    pricePerMonth: 74000,
    bedsLeft: 5,
    services: ['24/7 Nursing', 'Palliative care', 'Family visiting hours', 'Home-style meals', 'CCTV monitored'],
    scores: [
      { label: 'Hygiene', value: 4.7 },
      { label: 'Staff behaviour', value: 4.6 },
      { label: 'Medical care', value: 4.5 },
      { label: 'Food', value: 4.8 },
      { label: 'Value for money', value: 4.4 },
    ],
    phone: '+91 22 4120 5500',
  },
  {
    id: 'aarogya-daycare',
    name: 'Aarogya Physio & Day Care',
    type: 'Physiotherapy & day care',
    locality: 'Anna Nagar West',
    city: 'Chennai',
    photo: centreImg,
    photoCount: 8,
    rating: 4.4,
    reviews: 51,
    since: 2020,
    licence: 'TN-CEA-2022/1177',
    staffRatio: '1 : 5',
    pricePerDay: 1400,
    pricePerMonth: 34000,
    bedsLeft: 8,
    services: ['Physiotherapy', 'Day care', 'Doctor on call', 'Meals'],
    scores: [
      { label: 'Hygiene', value: 4.5 },
      { label: 'Staff behaviour', value: 4.4 },
      { label: 'Medical care', value: 4.3 },
      { label: 'Food', value: 4.1 },
      { label: 'Value for money', value: 4.7 },
    ],
    phone: '+91 44 4120 5500',
  },
]

export const equipment: Equipment[] = [
  {
    id: 'wheelchair',
    name: 'Foldable wheelchair',
    category: 'Mobility',
    photo: eqWheelchairImg,
    perDay: 120,
    perMonth: 1800,
    deposit: 2000,
    condition: 'Refurbished · Grade A',
    availableIn: '560076',
  },
  {
    id: 'oxygen',
    name: 'Oxygen concentrator 5L',
    category: 'Respiratory',
    photo: eqOxygenImg,
    perDay: 450,
    perMonth: 8500,
    deposit: 10000,
    condition: 'New',
    availableIn: '560076',
  },
  {
    id: 'bed',
    name: 'Electric hospital bed',
    category: 'Hospital furniture',
    photo: eqBedImg,
    perDay: 380,
    perMonth: 6900,
    deposit: 8000,
    condition: 'Refurbished · Grade A',
    availableIn: '560076',
  },
]

export const equipmentCategories = ['Mobility', 'Respiratory', 'Hospital furniture', 'Monitoring', 'ICU-grade']

export const nurseById = (id: string | null | undefined) => nurses.find((n) => n.id === id)
export const centreById = (id: string | null | undefined) => centres.find((c) => c.id === id)
export const equipmentById = (id: string | null | undefined) => equipment.find((e) => e.id === id)
