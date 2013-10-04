;; this is obsolete ... use migrations instead

drop table if exists people;
create table people (
    id int not null auto_increment,
    email varchar(255) not null,
    name text,
    primary key(id)
);

drop table if exists procedures;
create table procedures (
    id int not null auto_increment,
    title TEXT not null,
    person_id int not null,
    created_at datetime not null,
    modified_at datetime not null,
    body LONGTEXT,
    constraint fk_procedure_person foreign key (person_id) references
	people(id),
    primary key(id)
);

drop table if exists ratings;
create table ratings (
    id int not null auto_increment,
    procedure_id int not null,
    rating int not null,
    person_id int not null,
    constraint fk_ratings_procedure foreign key (procedure_id)
        references procedures(id),
    constraint fk_rating_person foreign key (person_id)
        references people(id),
    primary key(id)
);

drop table if exists tags;
create table tags (
    id int not null auto_increment,
    procedure_id int not null,
    raw_name varchar(255) not null,
    clean_name varchar(255) not null,
    person_id int not null,
    constraint fk_tag_procedure foreign key (procedure_id)
		references procedures(id),
	constraint fk_tag_person foreign key (person_id)
		references people(id),
    primary key(id)
);

drop table if exists changes;
create table changes (
    id int not null auto_increment,
    procedure_id int not null,
    person_id int not null,
    body LONGTEXT not null,
    modified_at datetime not null,
    constraint fk_change_person foreign key (person_id) references
	people(id),
    constraint fk_change_procedure foreign key (procedure_id) references
	procedures(id),
    primary key(id)
);

drop table if exists procedure_views;
create table procedure_views (
    id int not null auto_increment,
    procedure_id int not null,
    person_id int not null,
    viewed_at datetime not null,
    constraint fk_procedure_views_procedure foreign key (procedure_id)
	references procedures(id),
    constraint fk_procedure_views_person foreign key (person_id)
	references people(id),
    primary key(id)
);

drop table if exists procedure_executes;
create table procedure_executes (
    id int not null auto_increment,
    procedure_id int not null,
    person_id int not null,
    executed_at datetime not null,
    constraint fk_procedure_executes_procedure foreign key (procedure_id)
	references procedures(id),
    constraint fk_procedure_executes_person foreign key (person_id)
	references people(id),
    primary key(id)
);

drop table if exists procedure_comments;
create table procedure_comments (
    id int not null auto_increment,
    procedure_id int not null,
    person_id int not null,
    comment text not null,
    created_at datetime not null,
    updated_at datetime not null,
    constraint fk_comment_person foreign key (person_id) references
	people(id),
    constraint fk_comment_procedure foreign key (procedure_id) references
	procedures(id),
    primary key(id)
);

drop table if exists administrators;
create table administrators (
    id int not null auto_increment,
    person_id int not null,
    constraint fk_admin_person foreign key (person_id) references
	people(id),
    primary key(id)
);

drop table if exists best_bets;
create table best_bets (
    id int not null auto_increment,
    procedure_id int not null,
    constraint fk_bestbet_procedure foreign key (procedure_id) references
	procedures(id),
    primary key(id)
);

drop table if exists testcases;
create table testcases (
    id int not null auto_increment,
    html LONGTEXT not null,
    action TEXT not null,
    target TEXT not null,
    text TEXT,
    slop TEXT,
    primary key(id)
);

drop table if exists usage_logs;
create table usage_logs (
    id INT not null auto_increment,
    person_id INT not null,
    procedure_id INT,
    created_at DATETIME not null,
    event INT not null,
    extra TEXT,
    constraint fk_usage_procedure foreign key (procedure_id) references
	procedures(id),
    constraint fk_usage_person foreign key (person_id) references
	people(id),
    primary key(id)
);
