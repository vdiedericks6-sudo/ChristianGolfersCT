# HNA course source assessment — 2 November 2026

HNA Find & Play (https://www.handicaps.co.za/find-and-play) is publicly searchable. Search by club name, select the matching suggestion, search, then open the result. The club pages inspected show 9/18-hole men/women categories, tee colour, course and slope ratings, par, stroke indexes and per-hole distances. Accessed in the rendered website; not an exhaustive audit of all listings. No official bulk data feed, licence or public API documentation was established during this review. Ask HNA for access and terms for app distribution, refresh, historical use and attribution before a bulk import. The separate WHS interoperability programme has its own terms (https://www.whs.com/articles/2024/2024-interoperability.html); those terms should not be treated as the HNA website's general terms.

## Cross-checks

- Stellenbosch: https://www.handicaps.co.za/club-detail?clubid=225 — HNA men's 18-hole page displays black 76.0/135, yellow 74.7/133, white 73.1/128, blue 69.6/122, red 67.7/116. The previously supplied 2024 club card has different ratings and some stroke indexes. HNA's men's black total displays 6609; the user-supplied black yardages convert to approximately 6633 metres. Units of the HNA page should be confirmed with the provider. Course layouts and validity dates need club/HNA confirmation. Do not overwrite the explicitly preserved club card or assign a rating to the user-supplied black distances based only on a colour match.
- Bellville: https://www.handicaps.co.za/club-detail?clubid=454 — HNA men's white displayed distances, hole pars and indexes agree with the existing 18-hole club scorecard, but its men's ratings differ from the club website: white 71.4/132 versus 71.6/132; blue 68.6/122 versus 68.8/123; red 66.7/116 versus 66.8/116. The live app continues to label the club's values provisional pending confirmation. Female categories and other tees were not checked during this pilot.
- Verified public contact numbers for these two clubs were filled only where missing, with the other data unchanged.

## Safe import requirements

Acquire an authorised machine-readable export or documented API, rights, refresh frequency, course/tee/layout identifiers, effective dates, measurement units, categories, and whether photos/coordinates are included. Reconcile club identities and nine/18/27-hole layouts; validate per-hole arrays and sums; compare ratings, par and indexes with supplied cards. Flag conflicts for club review and avoid altering rounds or old tee records. The current schema does not version hole indexes per round, so overwriting hole records could change historical calculations. Any official Handicap Index or score submission also needs separate provider authorisation.

The current database snapshot has 361 active course entries nationwide, including 70 Western Cape entries; that count has not been verified against HNA and may include aliases, closed facilities or omissions. A full reconciliation and database import has not been completed.

## HNA reconciliation update — 2 November 2026

- Kuilsrivier: HNA's 18-hole pars, stroke indexes and yellow, blue and red hole distances match the existing supplied card. Added six HNA men's/women's rating categories; retained the four earlier provisional categories and marked them unavailable for new rounds. The 108 new hole distances and their totals were verified. Source: https://www.handicaps.co.za/club-detail?clubid=209.
- Durbanville main course: HNA's 18-hole pars and indexes match both the existing course record and the club's hole guide at https://durbanvillegolfclub.co.za/course/. Added six white/blue/red men/women rating categories with 108 distances. Retained the prior unrated tee and marked it unavailable for new rounds. Source: https://www.handicaps.co.za/club-detail?clubid=459. The separate HNA par-3 layout has not been imported.

These are individual reconciliations, not a nationwide import. HNA's pages do not visibly state the measurement unit; Kuilsrivier distances match the previously supplied yardages converted to metres and Durbanville's white distances match the club guide labelled metres. Confirm all other tee units with HNA or the club. Hole imagery and verified front/middle/back coordinates are separate work. The remaining catalogue entries and ambiguous aliases need individual matching and verification.

## Tee availability — 2 November 2026

At the organiser's request, women's rated tee records are kept for historical reference but hidden from new round selection across courses. Migration `20261102125048` disables currently identified women's tees; a trigger defaults newly imported women's-labelled tees to unavailable. The existing round-creation guard rejects unavailable tees, while historic rows and their distances/ratings remain unchanged. To introduce women's tee support later, review and retire the `hide_new_womens_tees` trigger, re-enable the intended categories, and verify round creation and player-level tee selection. Existing apps must respect `selectable`; the current Android build does so. The admin website source also filters on `selectable`, but a previously deployed website version may still display outdated choices until redeployed; the database rejects those selections.

## Western Cape HNA update — 2 November 2026

- [Milnerton](https://www.handicaps.co.za/club-detail?clubid=464): added men's yellow, white and red tees for its par-71 layout. HNA's 18 pars and stroke indexes matched the existing hole records, which were preserved. The HNA par-72 layout has a different par at hole 6 and is excluded until layouts have independent hole pars. Totals were verified after import.
- [Royal Cape](https://www.handicaps.co.za/club-detail?clubid=468): added HNA's 18-hole pars, indexes and men's yellow, white and red tees. No existing holes, tees or rounds were present before import. Totals were verified after import.

No GPS green geometry or course images were supplied. Distances are treated as metres: Royal Cape's totals match an independently labelled metre source (https://golftraxx.com/scorecard?course_name=Royal+Cape+Golf+Club&fulladdress=&static=true&zipcode=7800SA); Milnerton units need club/HNA confirmation. The remainder of the Western Cape catalogue has not yet been reconciled. Stellenbosch and Bellville remain unchanged as directed; HNA values for them differ from previously loaded cards.
