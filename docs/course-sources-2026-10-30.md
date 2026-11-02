# Course source assessment — 30 October 2026

## GolfRSA

Sources: [Our Clubs](https://golfrsa.com/our-clubs/), [Rules of Competition](https://golfrsa.com/rules-of-competition/).

The accessible directory provides club names, addresses and map links, not a complete hole-by-hole dataset. Repeated contact numbers need independent verification. The navigation links to R&A rules and handicap resources. Older indexed handicap documents must not become current calculation specifications. No licensed imagery feed or bulk data API was established in this review. Link to official resources; obtain permission before republishing content.

## GolfAPI.io

Sources: [product and terms](https://golfapi.io/), [API reference](https://documenter.getpostman.com/view/1756312/UVeDsT2b).

The service documents scorecards, tee lengths, ratings and coordinates. It permits caching for own-product use but prohibits redistribution. Documentation describes Bearer authentication, country-filtered search, pagination and green/hazard point types. Coordinate points are not contour surfaces or satellite imagery. Actual South African coverage, field completeness and freshness remain untested without a provider key.

## Integration gates and implementation

1. Obtain GolfAPI.io access and confirm its South Africa country filter. Existing GolfCourseAPI credentials belong to a different service.
2. Put `GOLFAPI_IO_KEY` in ignored root `.env.local`, never in Flutter assets or Git. Run `python tool/check_golfapi_io.py --country ZAF`. The script makes at most ten read-only search requests, returns aggregate coverage, and does not import anything.
3. Review representative course detail and coordinate responses against official club scorecards. Check nine-hole layouts, multiple courses at one club, tee rating categories, measurement units and absent values. A zero-result search is not proof that no SA data exists.
4. Confirm contract rights for offline device caching, maps and public repository handling. Keep licensed course exports out of this public source repository.
5. Import through a server-side adapter with provider IDs, timestamps, provenance and a reviewed club/course crosswalk; do not overwrite verified data with nulls or estimated geometry.
6. Obtain photos and contour datasets separately with explicit reuse rights. Do not fabricate hole imagery, elevations or official handicap records.

No new provider course data has been imported. The probe is ready but coverage has not been measured.
