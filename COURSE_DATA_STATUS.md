# South African course data status

The app currently ships with a 361-course catalog and 828 hole records covering
52 courses. Thirty-six courses have an 18-hole record set; sixteen others have
nine holes recorded. The catalog and hole records are also loaded into the
configured Supabase project.

Hole records contain par, stroke index, and OpenStreetMap tee/green GPS points.
They do not provide surveyed tee-box positions, official per-tee distances,
course ratings, or slope ratings. Distances calculated between GPS points are
straight-line estimates and must not be presented as official scorecard
yardages. The 36 round-ready cards currently have a clearly labelled neutral
"Club (unrated)" tee setup (par course rating, slope 113, no official distance)
so a round can be entered while course rating data is sourced.

The catalog should not be described as every golf course in South Africa.
Counts vary by source and whether a directory counts clubs, courses, or
facilities. The R&A's 2025 participation report lists 408 South African
9-or-18-hole courses. GolfNode's current directory lists 432 represented
clubs. GolfRSA maintains an official club directory, but neither that page nor
the current local dataset supplies an open, licensed national set of official
hole scorecards and tee ratings.

Before claiming full national coverage or publishing official handicap
standings, reconcile course identifiers against an authoritative GolfRSA
directory and obtain permission to use each club's current scorecard and
course/tee ratings. Refresh closed/opened venues and obtain club confirmation
for hole order, par, stroke index, tee colours, and distance units. Preserve
source URL and verification date with each record.

Sources consulted:

- [GolfRSA Our Clubs](https://golfrsa.com/our-clubs/)
- [The R&A Global Golf Participation 2025 report](https://assets.randa.org/c42c7bf4-dca7-00ea-4f2e-373223f80f76/d0c84c59-aa7b-4b6c-a505-095aabc9dbdc/Sporting%20Insights%20Report_The%20R_A_Global%20Golf%20Participation%202025_May%202026.pdf)
- [GolfNode South African clubs directory](https://www.golfnode.co.za/clubs?country=ZA)
