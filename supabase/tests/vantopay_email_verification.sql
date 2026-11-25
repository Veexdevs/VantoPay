-- Run as database owner in SQL editor / psql. All test rows roll back.
begin;
do $$
declare uid uuid := gen_random_uuid(); r jsonb; i integer;
begin
  insert into auth.users(id, email) values(uid, uid::text || '@example.invalid');
  if not public.vantopay_issue_otp('vp-test-one', uid, 'test@example.invalid', 'signup', 'hash-one') then raise exception 'initial issuance failed'; end if;
  if public.vantopay_issue_otp('vp-test-two', uid, 'test@example.invalid', 'signup', 'hash-two') then raise exception 'cooldown bypassed'; end if;
  for i in 1..5 loop
    r := public.vantopay_consume_otp('vp-test-one', 'wrong');
    if (r->>'ok')::boolean then raise exception 'wrong code accepted'; end if;
  end loop;
  if (public.vantopay_consume_otp('vp-test-one', 'hash-one')->>'ok')::boolean then raise exception 'attempt limit bypassed'; end if;
  insert into public.vantopay_email_challenges(token_hash,user_id,email,purpose,code_hash,expires_at)
    values('vp-test-expired',uid,'test@example.invalid','device','hash',now()-interval '1 second');
  if (public.vantopay_consume_otp('vp-test-expired','hash')->>'ok')::boolean then raise exception 'expired code accepted'; end if;
  insert into public.vantopay_email_challenges(token_hash,user_id,email,purpose,code_hash)
    values('vp-test-valid',uid,'test@example.invalid','device','hash');
  if not (public.vantopay_consume_otp('vp-test-valid','hash')->>'ok')::boolean then raise exception 'valid code rejected'; end if;
  if (public.vantopay_consume_otp('vp-test-valid','hash')->>'ok')::boolean then raise exception 'replayed code accepted'; end if;
  if has_function_privilege('anon','public.vantopay_consume_otp(text,text)','EXECUTE')
    or has_function_privilege('authenticated','public.vantopay_consume_otp(text,text)','EXECUTE') then raise exception 'RPC exposed'; end if;
end $$;
rollback;
