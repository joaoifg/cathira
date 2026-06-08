create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nome        text not null,
  foto_url    text,
  cidade      text,
  geo         geography(point, 4326),
  reputacao   numeric(2,1) default 0 check (reputacao between 0 and 5),
  num_trocas  int default 0,
  criado_em   timestamptz default now()
);

create index on profiles using gist (geo);
