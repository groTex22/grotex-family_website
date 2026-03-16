insert into family_tree.relationship_types (code, name)
values
    ('parent_child', 'Родитель → ребенок');

insert into family_tree.persons
    (first_name, surname, patronymic, gender , birth_date, photo_url, note)
values
    ('Григорий', 'Рыжков', 'Константинович','male', '1996-02-22', null, 'глава семьи'),
    ('Антонина', 'Рыжкова', 'Александровна', 'female', '1996-09-16', null, 'жена'),
    ('София', 'Рыжкова', 'Григорьевна', 'female', '2020-06-20', null, null),
    ('Светлана', 'Рыжкова', 'Григорьевна', 'female', '2023-09-04', null, null),
    ('Анастасия', 'Рыжкова', 'Григорьевна', 'female', '2025-11-01', null, null);

insert into family_tree.person_relationships
    (person_id, related_person_id, relationship_type_id)
values
    (1, 3, (select id from family_tree.relationship_types where code = 'parent_child')),
    (2, 3, (select id from family_tree.relationship_types where code = 'parent_child')),
    (1, 4, (select id from family_tree.relationship_types where code = 'parent_child')),
    (2, 4, (select id from family_tree.relationship_types where code = 'parent_child')),
    (1, 5, (select id from family_tree.relationship_types where code = 'parent_child')),
    (2, 5, (select id from family_tree.relationship_types where code = 'parent_child'));

insert into family_tree.unions
    (person1_id, person2_id, status, start_date, note)
values
    (1, 2, 'active', '2020-02-15', 'брак Григория и Антонины');