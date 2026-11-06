# Achievement badges

The Profile page shows earned badges and progress. Badges are calculated from the signed-in player's records, not inserted by a client. A qualifying card is an 18-hole completed round with 18 confirmed hole scores for that player. Confirmation is in-app score confirmation, not independent competition attestation.

- **First Round:** one qualifying card.
- **Faithful Fairways:** five qualifying cards, recognising consistent scorekeeping and participation. It is not a judgement about personal conduct.
- **Birdie Moment:** a hole under par on a qualifying card, including better-than-birdie scores.
- **Playing Below Handicap:** a qualifying card with a recorded net result below the course par. This relies on course and handicap data being accurate.
- **Handicap Updated:** an administrator records a non-null, sourced change to the index after this feature starts.
- **Moving Forward:** a subsequent administrator-recorded change lowers the index, with both previous and new values available.

Handicap history starts when this feature is deployed; historical profile values are not fabricated. Badges reflect current database records and can change if records are corrected or removed. The underlying admin-sourced index is not represented as an official handicap-system integration. Offline scores count only once they have synced, been confirmed and their round has completed.
