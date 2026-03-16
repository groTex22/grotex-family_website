create or replace function family_tree.create_person(
    p_first_name varchar(100),
    p_surname varchar(100) default null,
    p_patronymic varchar(100) default null,
    p_gender family_tree.gender_type default 'unknown',
    p_birth_date date default null,
    p_death_date date default null,
    p_photo_url text default null,
    p_note text default null,
    p_parent_ids bigint[] default null,
    p_spouse_ids bigint[] default null
)
returns bigint
language plpgsql
as $$
declare
    v_created_person_id bigint;
    v_parent_id bigint;
    v_spouse_id bigint;
    v_parent_child_type_id smallint;
    v_person1_id bigint;
    v_person2_id bigint;
begin
    select rt.id
      into v_parent_child_type_id
      from family_tree.relationship_types rt
     where rt.code = 'parent_child';

    if v_parent_child_type_id is null then
        raise exception 'В справочнике relationship_types отсутствует код parent_child';
    end if;

    if p_birth_date is not null
       and p_death_date is not null
       and p_death_date < p_birth_date then
        raise exception 'Дата смерти не может быть раньше даты рождения';
    end if;

    insert into family_tree.persons (
        first_name,
        surname,
		patronymic,
        gender,
        birth_date,
        death_date,
        photo_url,
        note
    )
    values (
        p_first_name,
        p_surname,
		p_patronymic,
        p_gender,
        p_birth_date,
        p_death_date,
        p_photo_url,
        p_note
    )
    returning id into v_created_person_id;

    if p_parent_ids is not null then
        foreach v_parent_id in array p_parent_ids
        loop
            if v_parent_id is null then
                continue;
            end if;

            if v_parent_id = v_created_person_id then
                raise exception 'Человек не может быть родителем самого себя';
            end if;

            if not exists (
                select 1
                  from family_tree.persons p
                 where p.id = v_parent_id
            ) then
                raise exception 'Родитель с id=% не найден', v_parent_id;
            end if;

            insert into family_tree.person_relationships (
                person_id,
                related_person_id,
                relationship_type_id
            )
            values (
                v_parent_id,
                v_created_person_id,
                v_parent_child_type_id
            )
            on conflict do nothing;
        end loop;
    end if;

    if p_spouse_ids is not null then
        foreach v_spouse_id in array p_spouse_ids
        loop
            if v_spouse_id is null then
                continue;
            end if;

            if v_spouse_id = v_created_person_id then
                raise exception 'Человек не может быть супругом самого себя';
            end if;

            if not exists (
                select 1
                  from family_tree.persons p
                 where p.id = v_spouse_id
            ) then
                raise exception 'Супруг с id=% не найден', v_spouse_id;
            end if;

            v_person1_id := least(v_created_person_id, v_spouse_id);
            v_person2_id := greatest(v_created_person_id, v_spouse_id);

            if not exists (
                select 1
                  from family_tree.unions u
                 where u.person1_id = v_person1_id
                   and u.person2_id = v_person2_id
                   and u.status = 'active'
            ) then
                insert into family_tree.unions (
                    person1_id,
                    person2_id,
                    status
                )
                values (
                    v_person1_id,
                    v_person2_id,
                    'active'
                );
            end if;
        end loop;
    end if;

    return v_created_person_id;
end;
$$;

    
create or replace procedure family_tree.create_person(
    in p_first_name varchar(100),
    in p_surname varchar(100) default null,
    in p_patronymic varchar(100) default null,
    in p_gender family_tree.gender_type default 'unknown',
    in p_birth_date date default null,
    in p_death_date date default null,
    in p_photo_url text default null,
    in p_note text default null,
    in p_parent_ids bigint[] default null,
    in p_spouse_ids bigint[] default null,
    inout p_created_person_id bigint default null
)
language plpgsql
as $$
begin
    p_created_person_id := family_tree.create_person_fn(
        p_first_name => p_first_name,
        p_surname => p_surname,
		p_patronymic => p_patronymic,
        p_gender => p_gender,
        p_birth_date => p_birth_date,
        p_death_date => p_death_date,
        p_photo_url => p_photo_url,
        p_note => p_note,
        p_parent_ids => p_parent_ids,
        p_spouse_ids => p_spouse_ids
    );
end;
$$;