-- App-specific, server-only state. No changes to other apps' auth configuration.
create table public.vantopay_email_challenges (
  token_hash text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  purpose text not null check (purpose in ('signup', 'device')),
  code_hash text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '5 minutes',
  attempts integer not null default 0 check (attempts between 0 and 5),
  consumed_at timestamptz
);
create index on public.vantopay_email_challenges(user_id, created_at desc);
create index on public.vantopay_email_challenges(expires_at);
create table public.vantopay_trusted_devices (
  token_hash text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);
create index on public.vantopay_trusted_devices(expires_at);
create table public.vantopay_auth_limits (
  bucket_key text primary key,
  hits integer not null default 1,
  expires_at timestamptz not null
);
alter table public.vantopay_email_challenges enable row level security;
alter table public.vantopay_trusted_devices enable row level security;
alter table public.vantopay_auth_limits enable row level security;
revoke all on public.vantopay_email_challenges, public.vantopay_trusted_devices, public.vantopay_auth_limits from anon, authenticated;
grant all on public.vantopay_email_challenges, public.vantopay_trusted_devices, public.vantopay_auth_limits to service_role;

create function public.vantopay_auth_limit(p_key text, p_limit integer, p_window integer)
returns boolean language plpgsql security definer set search_path = '' as $$
declare n integer; bucket text;
begin
  bucket := p_key || ':' || floor(extract(epoch from now()) / p_window)::text;
  insert into public.vantopay_auth_limits(bucket_key, expires_at)
    values (bucket, now() + make_interval(secs => p_window * 2))
    on conflict(bucket_key) do update set hits = public.vantopay_auth_limits.hits + 1
    returning hits into n;
  return n <= p_limit;
end;
$$;

create function public.vantopay_issue_otp(p_token text, p_user uuid, p_email text, p_purpose text, p_code text)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('vp-otp:' || p_user::text, 0));
  if exists(select 1 from public.vantopay_email_challenges where user_id = p_user and created_at > now() - interval '60 seconds') then
    return false;
  end if;
  if (select count(*) from public.vantopay_email_challenges where user_id = p_user and created_at > now() - interval '1 hour') >= 10 then
    return false;
  end if;
  update public.vantopay_email_challenges set consumed_at = now() where user_id = p_user and consumed_at is null;
  insert into public.vantopay_email_challenges(token_hash, user_id, email, purpose, code_hash)
    values (p_token, p_user, p_email, p_purpose, p_code);
  return true;
end;
$$;

-- Row lock makes attempts and one-time consumption atomic across server instances.
create function public.vantopay_consume_otp(p_token text, p_code text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare c public.vantopay_email_challenges%rowtype;
begin
  select * into c from public.vantopay_email_challenges where token_hash = p_token for update;
  if not found or c.consumed_at is not null or c.expires_at <= now() or c.attempts >= 5 then
    return jsonb_build_object('ok', false);
  end if;
  update public.vantopay_email_challenges set attempts = attempts + 1,
    consumed_at = case when attempts + 1 >= 5 or code_hash = p_code then now() else null end
    where token_hash = p_token;
  if c.code_hash <> p_code then return jsonb_build_object('ok', false); end if;
  return jsonb_build_object('ok', true, 'user_id', c.user_id, 'email', c.email, 'purpose', c.purpose);
end;
$$;

create function public.vantopay_unconfirmed_user(p_email text)
returns uuid language sql security definer set search_path = '' as $$
  select id from auth.users where lower(email) = lower(p_email) and email_confirmed_at is null limit 1;
$$;

revoke all on function public.vantopay_auth_limit(text, integer, integer),
  public.vantopay_issue_otp(text, uuid, text, text, text),
  public.vantopay_consume_otp(text, text), public.vantopay_unconfirmed_user(text)
  from public, anon, authenticated;
grant execute on function public.vantopay_auth_limit(text, integer, integer),
  public.vantopay_issue_otp(text, uuid, text, text, text),
  public.vantopay_consume_otp(text, text), public.vantopay_unconfirmed_user(text)
  to service_role;
