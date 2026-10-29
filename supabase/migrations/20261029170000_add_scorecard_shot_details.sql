alter table public.hole_scores
  add column if not exists sand_shots integer not null default 0
    check (sand_shots between 0 and 10),
  add column if not exists fairway text
    check (fairway in ('left', 'hit', 'right', 'missed')),
  add column if not exists green_in_regulation boolean;

comment on column public.hole_scores.fairway is
  'Fairway outcome from the tee: left, hit, right, missed; null when not recorded.';
comment on column public.hole_scores.green_in_regulation is
  'Whether the green was reached in regulation; null when not recorded.';
