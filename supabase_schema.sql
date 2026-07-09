
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.longan_app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

insert into public.longan_app_settings (key, value)
values ('admin_password_hash', extensions.crypt('3304', extensions.gen_salt('bf')))
on conflict (key) do nothing;

create table if not exists public.longan_cash_bills (
  id uuid primary key default extensions.gen_random_uuid(),
  bill_id text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  bill_date date not null default (timezone('Asia/Bangkok', now())::date),
  bill_time text not null default to_char(timezone('Asia/Bangkok', now()), 'HH24:MI'),
  business_name text not null default 'บิลเงินสด TK พัฒนาพืชผล',
  customer_name text not null,
  customer_phone text not null default '',
  seller_phone text not null default '080.825.6553',
  basket_kg numeric(12,2) not null default 27,
  rows jsonb not null default '[]'::jsonb,
  totals jsonb not null default '{}'::jsonb,
  constraint longan_cash_rows_array check (jsonb_typeof(rows) = 'array'),
  constraint longan_cash_totals_object check (jsonb_typeof(totals) = 'object')
);

create index if not exists longan_cash_bills_bill_date_idx on public.longan_cash_bills (bill_date desc);
create index if not exists longan_cash_bills_created_at_idx on public.longan_cash_bills (created_at desc);
create index if not exists longan_cash_bills_customer_idx on public.longan_cash_bills using gin (to_tsvector('simple', customer_name));

create table if not exists public.longan_delivery_bills (
  id uuid primary key default extensions.gen_random_uuid(),
  delivery_id text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  delivery_date date not null default (timezone('Asia/Bangkok', now())::date),
  title text not null default 'บิลส่งของ TK พืชผล',
  company_name text not null default 'บริษัท ไทยหวั้ง อโกรโปรดักส์ อินเตอร์เนชั่นแนล',
  company_address text not null default '176 หมู่ 6 ตำบลสันทรายงาม อำเภอเทิง จังหวัด เชียงราย 57160',
  basket_kg numeric(12,2) not null default 27,
  rows jsonb not null default '[]'::jsonb,
  totals jsonb not null default '{}'::jsonb,
  freight_text text not null default 'ราคานี้รวมค่าบรรทุก',
  vehicle_province text not null default 'ทะเบียนรถ พะเยา',
  vehicle_plate text not null default '70-3322 พะเยา',
  sender_label text not null default 'จาก ตี๋ (พะเยา รหัส 004)',
  sender_name text not null default 'นายทองบุญ ตุ้ยคำ',
  bank_name text not null default 'ธนาคารกสิกรไทย สาขาสี่แยกแม่ต๋ำพะเยา',
  account_no text not null default 'เลขที่บัญชี 448 - 2 - 19679 - 4',
  account_type text not null default '(ออมทรัพย์)',
  signature_sender text not null default 'ตี๋ (พะเยา)',
  constraint longan_delivery_rows_array check (jsonb_typeof(rows) = 'array'),
  constraint longan_delivery_totals_object check (jsonb_typeof(totals) = 'object')
);

create index if not exists longan_delivery_bills_date_idx on public.longan_delivery_bills (delivery_date desc);
create index if not exists longan_delivery_bills_created_at_idx on public.longan_delivery_bills (created_at desc);

alter table public.longan_app_settings enable row level security;
alter table public.longan_cash_bills enable row level security;
alter table public.longan_delivery_bills enable row level security;

revoke all on table public.longan_app_settings from anon, authenticated;
revoke all on table public.longan_cash_bills from anon, authenticated;
revoke all on table public.longan_delivery_bills from anon, authenticated;

create or replace function public.longan_make_id(p_prefix text)
returns text
language sql
volatile
set search_path = public, extensions
as $$
  select p_prefix || '-' || to_char(timezone('Asia/Bangkok', now()), 'YYYYMMDD-HH24MISS') || '-' || lpad((floor(random() * 900) + 100)::int::text, 3, '0')
$$;

create or replace function public.longan_cash_record_json(p_row public.longan_cash_bills)
returns jsonb
language sql
stable
set search_path = public
as $$
  select jsonb_build_object(
    'billId', p_row.bill_id,
    'createdAt', to_char(p_row.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'updatedAt', case when p_row.updated_at is null then null else to_char(p_row.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') end,
    'date', to_char(p_row.bill_date, 'YYYY-MM-DD'),
    'time', p_row.bill_time,
    'businessName', p_row.business_name,
    'customerName', p_row.customer_name,
    'customerPhone', p_row.customer_phone,
    'sellerPhone', p_row.seller_phone,
    'basketKg', p_row.basket_kg,
    'rows', p_row.rows,
    'totals', p_row.totals
  )
$$;

create or replace function public.longan_delivery_record_json(p_row public.longan_delivery_bills)
returns jsonb
language sql
stable
set search_path = public
as $$
  select jsonb_build_object(
    'deliveryId', p_row.delivery_id,
    'createdAt', to_char(p_row.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'updatedAt', case when p_row.updated_at is null then null else to_char(p_row.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') end,
    'date', to_char(p_row.delivery_date, 'YYYY-MM-DD'),
    'title', p_row.title,
    'companyName', p_row.company_name,
    'companyAddress', p_row.company_address,
    'basketKg', p_row.basket_kg,
    'rows', p_row.rows,
    'totals', p_row.totals,
    'freightText', p_row.freight_text,
    'vehicleProvince', p_row.vehicle_province,
    'vehiclePlate', p_row.vehicle_plate,
    'senderLabel', p_row.sender_label,
    'senderName', p_row.sender_name,
    'bankName', p_row.bank_name,
    'accountNo', p_row.account_no,
    'accountType', p_row.account_type,
    'signatureSender', p_row.signature_sender
  )
$$;

create or replace function public.longan_assert_admin(p_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;
begin
  select value into v_hash from public.longan_app_settings where key = 'admin_password_hash';
  if v_hash is null or extensions.crypt(coalesce(p_password, ''), v_hash) <> v_hash then
    raise exception 'รหัสผ่านผู้ดูแลไม่ถูกต้อง' using errcode = '28000';
  end if;
end;
$$;

create or replace function public.longan_admin_login(admin_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform public.longan_assert_admin(admin_password);
  return jsonb_build_object('ok', true, 'message', 'เข้าสู่ระบบผู้ดูแลสำเร็จ');
end;
$$;

create or replace function public.longan_change_admin_password(old_password text, new_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform public.longan_assert_admin(old_password);
  if coalesce(length(new_password), 0) < 4 then
    raise exception 'รหัสผ่านใหม่ต้องมีอย่างน้อย 4 ตัวอักษร';
  end if;
  update public.longan_app_settings
  set value = extensions.crypt(new_password, extensions.gen_salt('bf')),
      updated_at = now()
  where key = 'admin_password_hash';
  return jsonb_build_object('ok', true, 'message', 'เปลี่ยนรหัสผ่านผู้ดูแลสำเร็จ');
end;
$$;

create or replace function public.longan_create_cash_bill(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.longan_cash_bills%rowtype;
  v_customer text := trim(coalesce(payload->>'customerName', ''));
  v_weight numeric := coalesce(nullif(payload #>> '{totals,totalWeightKg}', '')::numeric, 0);
  v_amount numeric := coalesce(nullif(payload #>> '{totals,totalAmount}', '')::numeric, 0);
  v_date date := coalesce(nullif(payload->>'date', '')::date, timezone('Asia/Bangkok', now())::date);
  v_time text := coalesce(nullif(payload->>'time', ''), to_char(timezone('Asia/Bangkok', now()), 'HH24:MI'));
begin
  if v_customer = '' then
    raise exception 'กรุณาระบุชื่อลูกค้า';
  end if;
  if v_weight <= 0 or v_amount <= 0 then
    raise exception 'น้ำหนักหรือจำนวนเงินรวมต้องมากกว่า 0';
  end if;

  insert into public.longan_cash_bills (
    bill_id, created_at, bill_date, bill_time, business_name, customer_name, customer_phone, seller_phone, basket_kg, rows, totals
  )
  values (
    coalesce(nullif(payload->>'billId', ''), public.longan_make_id('LY')),
    now(),
    v_date,
    v_time,
    coalesce(nullif(payload->>'businessName', ''), 'บิลเงินสด TK พัฒนาพืชผล'),
    v_customer,
    coalesce(payload->>'customerPhone', ''),
    coalesce(nullif(payload->>'sellerPhone', ''), '080.825.6553'),
    coalesce(nullif(payload->>'basketKg', '')::numeric, 27),
    coalesce(payload->'rows', '[]'::jsonb),
    coalesce(payload->'totals', '{}'::jsonb)
  )
  returning * into v_row;

  return jsonb_build_object('ok', true, 'record', public.longan_cash_record_json(v_row));
end;
$$;

create or replace function public.longan_update_cash_bill(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.longan_cash_bills%rowtype;
  v_bill_id text := trim(coalesce(payload->>'billId', ''));
  v_customer text := trim(coalesce(payload->>'customerName', ''));
  v_weight numeric := coalesce(nullif(payload #>> '{totals,totalWeightKg}', '')::numeric, 0);
  v_amount numeric := coalesce(nullif(payload #>> '{totals,totalAmount}', '')::numeric, 0);
begin
  perform public.longan_assert_admin(payload->>'password');

  if v_bill_id = '' then raise exception 'ไม่พบเลขที่บิลที่ต้องการแก้ไข'; end if;
  if v_customer = '' then raise exception 'กรุณาระบุชื่อลูกค้า'; end if;
  if v_weight <= 0 or v_amount <= 0 then raise exception 'น้ำหนักหรือจำนวนเงินรวมต้องมากกว่า 0'; end if;

  update public.longan_cash_bills
  set
    created_at = coalesce(nullif(payload->>'createdAt', '')::timestamptz, created_at),
    updated_at = now(),
    bill_date = coalesce(nullif(payload->>'date', '')::date, bill_date),
    bill_time = coalesce(nullif(payload->>'time', ''), bill_time),
    business_name = coalesce(nullif(payload->>'businessName', ''), business_name),
    customer_name = v_customer,
    customer_phone = coalesce(payload->>'customerPhone', ''),
    seller_phone = coalesce(nullif(payload->>'sellerPhone', ''), seller_phone),
    basket_kg = coalesce(nullif(payload->>'basketKg', '')::numeric, basket_kg),
    rows = coalesce(payload->'rows', rows),
    totals = coalesce(payload->'totals', totals)
  where bill_id = v_bill_id
  returning * into v_row;

  if not found then
    raise exception 'ไม่พบเลขที่บิล: %', v_bill_id;
  end if;

  return jsonb_build_object('ok', true, 'message', 'แก้ไขรายการสำเร็จ', 'record', public.longan_cash_record_json(v_row));
end;
$$;

create or replace function public.longan_delete_cash_bill(p_bill_id text, admin_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_deleted text;
begin
  perform public.longan_assert_admin(admin_password);
  delete from public.longan_cash_bills
  where bill_id = p_bill_id
  returning bill_id into v_deleted;
  if not found then
    raise exception 'ไม่พบเลขที่บิล: %', p_bill_id;
  end if;
  return jsonb_build_object('ok', true, 'message', 'ลบรายการสำเร็จ', 'billId', v_deleted);
end;
$$;

create or replace function public.longan_read_all()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_records jsonb;
begin
  select coalesce(jsonb_agg(public.longan_cash_record_json(b) order by b.created_at desc), '[]'::jsonb)
  into v_records
  from public.longan_cash_bills b;

  return jsonb_build_object(
    'ok', true,
    'records', v_records,
    'count', jsonb_array_length(v_records),
    'source', 'supabase',
    'serverTime', to_char(now() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
  );
end;
$$;

create or replace function public.longan_create_delivery(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.longan_delivery_bills%rowtype;
  v_weight numeric := coalesce(nullif(payload #>> '{totals,totalWeightKg}', '')::numeric, 0);
  v_amount numeric := coalesce(nullif(payload #>> '{totals,totalAmount}', '')::numeric, 0);
  v_date date := coalesce(nullif(payload->>'date', '')::date, timezone('Asia/Bangkok', now())::date);
begin
  if v_weight <= 0 or v_amount <= 0 then
    raise exception 'น้ำหนักหรือจำนวนเงินรวมของใบส่งของต้องมากกว่า 0';
  end if;

  insert into public.longan_delivery_bills (
    delivery_id, created_at, delivery_date, title, company_name, company_address, basket_kg, rows, totals,
    freight_text, vehicle_province, vehicle_plate, sender_label, sender_name, bank_name, account_no, account_type, signature_sender
  )
  values (
    coalesce(nullif(payload->>'deliveryId', ''), public.longan_make_id('DL')),
    now(),
    v_date,
    coalesce(nullif(payload->>'title', ''), 'บิลส่งของ TK พืชผล'),
    coalesce(nullif(payload->>'companyName', ''), 'บริษัท ไทยหวั้ง อโกรโปรดักส์ อินเตอร์เนชั่นแนล'),
    coalesce(nullif(payload->>'companyAddress', ''), '176 หมู่ 6 ตำบลสันทรายงาม อำเภอเทิง จังหวัด เชียงราย 57160'),
    coalesce(nullif(payload->>'basketKg', '')::numeric, 27),
    coalesce(payload->'rows', '[]'::jsonb),
    coalesce(payload->'totals', '{}'::jsonb),
    coalesce(nullif(payload->>'freightText', ''), 'ราคานี้รวมค่าบรรทุก'),
    coalesce(nullif(payload->>'vehicleProvince', ''), 'ทะเบียนรถ พะเยา'),
    coalesce(nullif(payload->>'vehiclePlate', ''), '70-3322 พะเยา'),
    coalesce(nullif(payload->>'senderLabel', ''), 'จาก ตี๋ (พะเยา รหัส 004)'),
    coalesce(nullif(payload->>'senderName', ''), 'นายทองบุญ ตุ้ยคำ'),
    coalesce(nullif(payload->>'bankName', ''), 'ธนาคารกสิกรไทย สาขาสี่แยกแม่ต๋ำพะเยา'),
    coalesce(nullif(payload->>'accountNo', ''), 'เลขที่บัญชี 448 - 2 - 19679 - 4'),
    coalesce(nullif(payload->>'accountType', ''), '(ออมทรัพย์)'),
    coalesce(nullif(payload->>'signatureSender', ''), 'ตี๋ (พะเยา)')
  )
  returning * into v_row;

  return jsonb_build_object('ok', true, 'record', public.longan_delivery_record_json(v_row));
end;
$$;

create or replace function public.longan_update_delivery(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.longan_delivery_bills%rowtype;
  v_delivery_id text := trim(coalesce(payload->>'deliveryId', ''));
  v_weight numeric := coalesce(nullif(payload #>> '{totals,totalWeightKg}', '')::numeric, 0);
  v_amount numeric := coalesce(nullif(payload #>> '{totals,totalAmount}', '')::numeric, 0);
begin
  perform public.longan_assert_admin(payload->>'password');

  if v_delivery_id = '' then raise exception 'ไม่พบเลขที่ใบส่งของที่ต้องการแก้ไข'; end if;
  if v_weight <= 0 or v_amount <= 0 then raise exception 'น้ำหนักหรือจำนวนเงินรวมของใบส่งของต้องมากกว่า 0'; end if;

  update public.longan_delivery_bills
  set
    created_at = coalesce(nullif(payload->>'createdAt', '')::timestamptz, created_at),
    updated_at = now(),
    delivery_date = coalesce(nullif(payload->>'date', '')::date, delivery_date),
    title = coalesce(nullif(payload->>'title', ''), title),
    company_name = coalesce(nullif(payload->>'companyName', ''), company_name),
    company_address = coalesce(nullif(payload->>'companyAddress', ''), company_address),
    basket_kg = coalesce(nullif(payload->>'basketKg', '')::numeric, basket_kg),
    rows = coalesce(payload->'rows', rows),
    totals = coalesce(payload->'totals', totals),
    freight_text = coalesce(nullif(payload->>'freightText', ''), freight_text),
    vehicle_province = coalesce(nullif(payload->>'vehicleProvince', ''), vehicle_province),
    vehicle_plate = coalesce(nullif(payload->>'vehiclePlate', ''), vehicle_plate),
    sender_label = coalesce(nullif(payload->>'senderLabel', ''), sender_label),
    sender_name = coalesce(nullif(payload->>'senderName', ''), sender_name),
    bank_name = coalesce(nullif(payload->>'bankName', ''), bank_name),
    account_no = coalesce(nullif(payload->>'accountNo', ''), account_no),
    account_type = coalesce(nullif(payload->>'accountType', ''), account_type),
    signature_sender = coalesce(nullif(payload->>'signatureSender', ''), signature_sender)
  where delivery_id = v_delivery_id
  returning * into v_row;

  if not found then
    raise exception 'ไม่พบเลขที่ใบส่งของ: %', v_delivery_id;
  end if;

  return jsonb_build_object('ok', true, 'message', 'แก้ไขใบส่งของสำเร็จ', 'record', public.longan_delivery_record_json(v_row));
end;
$$;

create or replace function public.longan_delete_delivery(p_delivery_id text, admin_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_deleted text;
begin
  perform public.longan_assert_admin(admin_password);
  delete from public.longan_delivery_bills
  where delivery_id = p_delivery_id
  returning delivery_id into v_deleted;
  if not found then
    raise exception 'ไม่พบเลขที่ใบส่งของ: %', p_delivery_id;
  end if;
  return jsonb_build_object('ok', true, 'message', 'ลบใบส่งของสำเร็จ', 'deliveryId', v_deleted);
end;
$$;

create or replace function public.longan_read_all_deliveries()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_records jsonb;
begin
  select coalesce(jsonb_agg(public.longan_delivery_record_json(d) order by d.created_at desc), '[]'::jsonb)
  into v_records
  from public.longan_delivery_bills d;

  return jsonb_build_object(
    'ok', true,
    'records', v_records,
    'count', jsonb_array_length(v_records),
    'source', 'supabase',
    'serverTime', to_char(now() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
  );
end;
$$;

grant usage on schema public to anon, authenticated;

grant execute on function public.longan_admin_login(text) to anon, authenticated;
grant execute on function public.longan_change_admin_password(text, text) to anon, authenticated;
grant execute on function public.longan_create_cash_bill(jsonb) to anon, authenticated;
grant execute on function public.longan_update_cash_bill(jsonb) to anon, authenticated;
grant execute on function public.longan_delete_cash_bill(text, text) to anon, authenticated;
grant execute on function public.longan_read_all() to anon, authenticated;
grant execute on function public.longan_create_delivery(jsonb) to anon, authenticated;
grant execute on function public.longan_update_delivery(jsonb) to anon, authenticated;
grant execute on function public.longan_delete_delivery(text, text) to anon, authenticated;
grant execute on function public.longan_read_all_deliveries() to anon, authenticated;

comment on table public.longan_cash_bills is 'Longan cash bill records migrated from Google Apps Script/Google Sheets.';
comment on table public.longan_delivery_bills is 'Longan delivery note records migrated from Google Apps Script/Google Sheets.';

-- Harden internal admin helper: it is used only inside SECURITY DEFINER RPC functions.
revoke execute on function public.longan_assert_admin(text) from public;
revoke execute on function public.longan_assert_admin(text) from anon, authenticated;
