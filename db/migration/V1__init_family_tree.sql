create schema if not exists family_tree;

create type family_tree.union_status_type as enum (
    'active',
    'ended'
);

comment on type family_tree.union_status_type is
'Статус союза между людьми: active — текущий союз, ended — завершенный';


create table family_tree.relationship_types (
    id smallserial primary key,
    code varchar(50) not null unique,
    name varchar(100) not null,
    created_at timestamptz not null default now()
);

comment on table family_tree.relationship_types is
'Справочник типов направленных связей между людьми';

create table family_tree.persons (
    id bigserial primary key,
    first_name varchar(100) not null,
    surname  varchar(100) not null,
    Patronymic varchar(100),
    gender family_tree.gender_type not null default 'unknown',
    birth_date date,
    death_date date,
    photo_url text,
    note text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_persons_dates
        check (
            death_date is null
            or birth_date is null
            or death_date >= birth_date
        )
);

create table family_tree.person_relationships (
    id bigserial primary key,

    person_id bigint not null
        references family_tree.persons(id) on delete cascade,

    related_person_id bigint not null
        references family_tree.persons(id) on delete cascade,

    relationship_type_id smallint not null
        references family_tree.relationship_types(id),

    note text,
    created_at timestamptz not null default now(),

    constraint chk_person_relationships_not_self
        check (person_id <> related_person_id)
);


comment on table family_tree.person_relationships is
'Направленные связи между людьми (например родитель → ребенок)';

comment on column family_tree.person_relationships.person_id is
'Человек, от которого идет связь (например родитель)';

comment on column family_tree.person_relationships.related_person_id is
'Связанный человек (например ребенок)';

comment on column family_tree.person_relationships.relationship_type_id is
'Тип связи из справочника relationship_types';

create table family_tree.unions (
    id bigserial primary key,

    person1_id bigint not null
        references family_tree.persons(id) on delete cascade,

    person2_id bigint not null
        references family_tree.persons(id) on delete cascade,

    status family_tree.union_status_type not null default 'active',

    start_date date,
    end_date date,
    note text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_unions_not_self
        check (person1_id <> person2_id),

    constraint chk_unions_order
        check (person1_id < person2_id),

    constraint chk_unions_dates
        check (
            end_date is null
            or start_date is null
            or end_date >= start_date
        )
);
comment on table family_tree.unions is
'Союзы (браки/партнерства) между людьми';
comment on column family_tree.unions.person1_id is
'Первый человек в союзе (всегда с меньшим id для предотвращения дублей)';

comment on column family_tree.unions.person2_id is
'Второй человек в союзе';

comment on column family_tree.unions.status is
'Статус союза: active — текущий союз, ended — завершенный';

select * from family_tree.relationship_types;


create unique index index_family_tree_relationship_types_code
    on family_tree.relationship_types (code);

  
create index index_family_tree_person_relationships_person_id
    on family_tree.person_relationships (person_id);

create index index_family_tree_person_relationships_related_person_id
    on family_tree.person_relationships (related_person_id);

create index index_family_tree_person_relationships_relationship_type_id
    on family_tree.person_relationships (relationship_type_id);

create unique index index_family_tree_person_relationships_unique
    on family_tree.person_relationships (
        person_id,
        related_person_id,
        relationship_type_id
    );

create index index_family_tree_unions_person1_id
    on family_tree.unions (person1_id);

create index index_family_tree_unions_person2_id
    on family_tree.unions (person2_id);

create index index_family_tree_unions_status
    on family_tree.unions (status);