-- doc modules stockés : https://www.postgresql.org/docs/14/plpgsql.html

create schema if not exists banque;
set search_path to banque ;

/*
drop table if exists banque.agence cascade ;
drop table if exists banque.client cascade ;
drop table if exists banque.compte cascade ;
drop table if exists banque.compte_client cascade ;
drop table if exists banque.emprunt cascade ;
*/

create table banque.agence(
  nag integer constraint agence_pkey primary key,
  nomag varchar(70) not null,
  villeag varchar(30)
);


INSERT INTO banque.agence VALUES (2, 'E. Zola', 'Lille');
INSERT INTO banque.agence VALUES (1, 'J. Guesdes', 'Lille');
INSERT INTO banque.agence VALUES (3, 'C. Corot', 'Lens');


create table banque.client(
  ncli integer constraint client_pkey primary key,
  nomcli varchar(30) not null,
  prenomcli varchar(30) not null,
  villecli varchar(30)
);


INSERT INTO banque.client VALUES (10, 'Lagaffe', 'Gaston', 'Villeneuve d''''Ascq');
INSERT INTO banque.client VALUES (11, 'Tournesol', 'Tryphon', 'Lille');
INSERT INTO banque.client VALUES (12, 'Tsuno', 'Yoko', 'Lille');
INSERT INTO banque.client VALUES (13, 'Cru', 'Carmen', 'Lens');
INSERT INTO banque.client VALUES (14, 'Ackerman', 'Mikasa', 'Vimy');

create table banque.compte(
  ncompte integer constraint compte_pkey primary key,
  nag integer references agence,
  solde float default 0.0 not null,
  typecpte varchar(15)
);

INSERT INTO banque.compte VALUES (145, 1, 1020, 'cpte courant');
INSERT INTO banque.compte VALUES (176, 1, 500, 'livret A');
INSERT INTO banque.compte VALUES (978, 2, 1500, 'cpte courant');
INSERT INTO banque.compte VALUES (302, 1, 100, 'cpte courant');
INSERT INTO banque.compte VALUES (529, 3, 1000, 'Ass. Vie');


create table banque.compte_client(
  ncompte integer references compte,
  ncli integer references client,
  constraint compte_client_pkey primary key(ncompte, ncli)
);

INSERT INTO banque.compte_client VALUES (145, 10);
INSERT INTO banque.compte_client VALUES (176, 10);
INSERT INTO banque.compte_client VALUES (978, 12);
INSERT INTO banque.compte_client VALUES (978, 11);
INSERT INTO banque.compte_client VALUES (302, 12);
INSERT INTO banque.compte_client VALUES (529, 14);

create table banque.emprunt(
  nemprunt integer constraint emprunt_pkey primary key,
  ncompte integer not null references compte,
  montant float not null
);

INSERT INTO banque.emprunt VALUES (1, 978, 1000);
INSERT INTO banque.emprunt VALUES (2, 145, 1500);
INSERT INTO banque.emprunt VALUES (3, 978, 2000);
INSERT INTO banque.emprunt VALUES (4, 302, 4200);
