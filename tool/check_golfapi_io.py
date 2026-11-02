"""Read-only GolfAPI.io coverage probe. Never imports or modifies app course data.

python tool/check_golfapi_io.py --country ZAF
Requires GOLFAPI_IO_KEY in environment or root .env.local. Country filter syntax
must be confirmed with the supplier if the response is empty. Maximum 10 pages.
"""
import argparse
import json
import os
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def api_key():
    key = os.environ.get('GOLFAPI_IO_KEY', '').strip()
    if key:
        return key
    path = Path(__file__).resolve().parents[1] / '.env.local'
    if path.exists():
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            name, sep, value = line.partition('=')
            if sep and name.strip() == 'GOLFAPI_IO_KEY':
                return value.strip().strip('\"\'')
    raise SystemExit('Add GOLFAPI_IO_KEY to .env.local; this is separate from GOLFCOURSEAPI_KEY.')


def inspect(country, key):
    seen = {}
    total = None
    quota = None
    for page in range(1, 11):
        query = urlencode({'country': country, 'page': page})
        request = Request('https://golfapi.io/api/v2.3/courses?' + query,
                          headers={'Authorization': 'Bearer ' + key, 'Accept': 'application/json'})
        try:
            with urlopen(request, timeout=30) as response:
                data = json.load(response)
        except HTTPError as error:
            raise SystemExit(f'GolfAPI HTTP {error.code}; check access/quota. No app data changed.') from None
        except (URLError, TimeoutError, ValueError):
            raise SystemExit('GolfAPI request failed or returned invalid JSON. No app data changed.') from None
        rows = data.get('courses')
        if not isinstance(rows, list):
            raise SystemExit('Unexpected API response: courses array missing.')
        total = int(data.get('numAllCourses', len(rows)))
        quota = data.get('apiRequestsLeft')
        before = len(seen)
        for course in rows:
            if course.get('courseID'):
                seen[str(course['courseID'])] = course
        if not rows or len(seen) >= total or len(seen) == before:
            break
    courses = list(seen.values())
    def positive(field):
        return sum(float(c.get(field) or 0) > 0 for c in courses)
    return {
        'source': 'https://golfapi.io/docs/', 'country_filter': country,
        'reported_total': total, 'unique_courses_returned': len(courses),
        'pagination_complete': len(courses) == total,
        'courses_with_tee_yardages': positive('numTeesWithYardages'),
        'courses_with_ratings': positive('numTeesWithRatings'),
        'courses_with_coordinates': positive('numCoordinates'),
        'requests_left': quota,
        'limitations': 'Listing metadata only; individual hole coverage, freshness, imagery and licensing need verification.',
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--country', default='ZAF')
    args = parser.parse_args()
    print(json.dumps(inspect(args.country, api_key()), indent=2))
