-- ==============================================================================
-- ALLCURO — starter FAQs for the website and customer app (public.faqs).
-- Inserts only when the table is empty, so it never duplicates or overwrites
-- FAQs edited in the admin's Site Content. Safe to re-run.
-- ==============================================================================
insert into public.faqs (question, answer, sort_order)
select q, a, n
from (values
  (1, 'Can I book a nurse for just 30 minutes?',
      'Yes. For procedures like injections, wound dressing or catheter care, you can book a 30 or 45-minute visit without paying for a full shift.'),
  (2, 'How quickly can someone reach my home?',
      'Our verified clinicians are spread across the city. For urgent needs, an available clinician can usually reach your door within 45 to 60 minutes.'),
  (3, 'Are caregivers different from registered nurses?',
      'Yes. Registered nurses hold B.Sc or GNM qualifications and handle clinical care such as injections and post-operative care. Caregivers help with daily living — bathing, feeding, moving around and companionship.'),
  (4, 'Are the prices final?',
      'The price shown is the starting visit charge. Medicines, dressing materials and lab charges are extra where mentioned, and you see the full breakdown before you pay.'),
  (5, 'Can I reschedule or ask for a different person?',
      'Yes. You can reschedule or request a replacement through our 24/7 care desk with no penalty.')
) as v(n, q, a)
where not exists (select 1 from public.faqs);
