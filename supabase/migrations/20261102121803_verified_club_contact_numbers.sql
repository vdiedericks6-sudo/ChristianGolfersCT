-- Published club contact numbers cross-checked against HNA Find & Play.
-- Preserve any contact number previously curated by an administrator.
update public.courses set phone = '021 913 3100'
where id = 'bellville-golf-club' and (phone is null or btrim(phone) = '');
update public.courses set phone = '021 880 0103'
where id = 'stellenbosch-golf-club' and (phone is null or btrim(phone) = '');
