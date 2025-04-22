-- Complétez :
---------------------
-- NOM : Henniaux
-- PRENOM : Gaspar
-- Parcours : Machine Learning
---------------------

-- Connectez-vous avec votre compte postgresql

-- script de création des tables
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = notice;
SET row_security = off;

DROP SCHEMA IF EXISTS crous CASCADE;
create schema crous;
SET schema 'crous';

drop table if exists consommation;
drop table if exists carteMS;
drop table if exists personne;
drop table if exists tarif;


create table Tarif(
  id_tarif SERIAL primary key,
  tarif_repas NUMERIC(3,2) not null,
  constraint tarif_positif check (tarif_repas >= 0)
);

insert into tarif(tarif_repas) values(3.30);
insert into tarif(tarif_repas) values(4.93);
insert into tarif(tarif_repas) values(6.80);
insert into tarif(tarif_repas) values(7.48);

create table Personne(
  id_personne SERIAL primary key,
  nom Varchar(20) not null,
  prenom Varchar(50) not null,
  id_tarif INTEGER not null constraint personne_tarif_fkey references Tarif,
  solde NUMERIC(5,2) default 0.0 not null,
  constraint solde_positif check (solde >= 0.0),
  possede_carte Integer default 0 not null,
  constraint possede_carte_booleen check (possede_carte in (0,1))
);

insert into personne(nom,prenom,id_tarif,solde) values ('ALMOUZNI', 'Geneviève',(select id_tarif from tarif where tarif_repas = 3.3),50);
insert into personne(nom,prenom,id_tarif,solde) values ('NEWTON', 'Isaac',(select id_tarif from tarif where tarif_repas = 4.93),75);
insert into personne(nom,prenom,id_tarif,solde) values ('MIRZAKHANI', 'Maryam',(select id_tarif from tarif where tarif_repas = 6.8),80);
insert into personne(nom,prenom,id_tarif,solde) values ('CELSIUS', 'Anders',(select id_tarif from tarif where tarif_repas = 6.8),40);
insert into personne(nom,prenom,id_tarif,solde) values ('LISKOV', 'Barbara',(select id_tarif from tarif where tarif_repas = 3.3),0);
insert into personne(nom,prenom,id_tarif,solde) values ('GERMAIN', 'Sophie',(select id_tarif from tarif where tarif_repas = 4.93),10);


create table CarteMS(
  id_cms SERIAL primary key,
  proprietaire Integer not null constraint cms_personne_fkey references Personne,
  activee Integer default 1 not null,
  constraint activee_booleen check (activee in (0,1))
);

-- Issac Newton a perdu 1 carteMS, il a 1 carte desactivee et 1 carte activee dans la base
-- Barbara Liskov n'a pas de carte.
-- Sophie Germain a 1 carte desactivée
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'ALMOUZNI'),1);
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'NEWTON'),0);
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'MIRZAKHANI'),1);
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'NEWTON'),1);
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'CELSIUS'),1);
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'GERMAIN'),0);


-- on met à jour la colonne possede_carte
update personne
set possede_carte = (select coalesce(sum(activee),0) from cartems where proprietaire = id_personne);

create table Consommation(
  id_cms Integer not null constraint conso_cms_fkey references CarteMS,
  instant Timestamp,
  montant Numeric(4,2), -- sera calculé par trigger
  constraint montant_positif check (montant > 0.0),
  constraint Consommation_pkey primary key(id_cms, instant)
);

-- on crée artificiellement des consommations pour peupler la table
insert into consommation(id_cms, instant, montant)
values (1, current_timestamp - interval '1 day', 3.3) ;
insert into consommation(id_cms, instant, montant)
values (1, current_timestamp, 3.3) ;
insert into consommation(id_cms, instant, montant)
values (5, current_timestamp - interval '1 day', 6.8) ;
insert into consommation(id_cms, instant, montant)
values (5, current_timestamp, 6.8) ;
insert into consommation(id_cms, instant, montant)
values (6, current_timestamp - interval '1 month', 4.93) ;


------------------------------
-- Réponses aux questions :

----------------
-- Question 1 --
----------------

-- Fonction utilisée par les triggers pour l'insertion ou la mise à jour des cartes
CREATE OR REPLACE FUNCTION maj_possede_carte() RETURNS TRIGGER AS $$
DECLARE
    card_number INTEGER;
BEGIN
    SELECT COUNT(*) INTO card_number
    FROM CarteMS
    WHERE proprietaire = NEW.proprietaire AND activee = 1;

    UPDATE Personne
    SET possede_carte = card_number
    WHERE id_personne = NEW.proprietaire;

    IF card_number > 1 THEN
        RAISE EXCEPTION 'La personne a déjà une carte active';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger insertion
CREATE TRIGGER trigger_insert_cartems
AFTER INSERT ON cartems
FOR EACH ROW
EXECUTE FUNCTION maj_possede_carte();

-- Trigger update
CREATE TRIGGER trigger_update_cartems
AFTER UPDATE ON cartems
FOR EACH ROW
EXECUTE FUNCTION maj_possede_carte();

--pour tester le trigger :
-- on ajoute une carte pour celsius, mais il a deja une carte activee
insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'CELSIUS'),1);

--> erreur parce qu'il a deja une carte activee
--ERROR:  new row for relation "personne" violates check constraint "possede_carte_booleen"
...

-- on desactive la carte
update carteMS
set activee = 0 where id_cms = 5;
--> possede_carte doit passer à 0 pour Anders Celsius

insert into CarteMS(proprietaire, activee) values ((select id_personne from personne where nom = 'CELSIUS'),1);
--> possede_carte doit repasser à 1 pour Anders Celsius


----------------
-- Question 2 --
----------------

-- Trigger de vérification des consommations
CREATE OR REPLACE FUNCTION conso_valide()
RETURNS TRIGGER
AS $$
    DECLARE
        solde_available NUMERIC(5,2);
        active_card INT;
        price NUMERIC(3,2);
    BEGIN
        SELECT c.activee, p.solde, t.tarif_repas INTO active_card, solde_available, price
        FROM Personne p
        JOIN CarteMS c ON p.id_personne = c.proprietaire
        JOIN Tarif t ON p.id_tarif = t.id_tarif
        WHERE c.id_cms = NEW.id_cms;

        IF active_card = 0 THEN
            RAISE EXCEPTION 'carte non active';
        END IF;

        UPDATE Personne
        SET solde = solde - price
        WHERE id_personne = (SELECT proprietaire FROM CarteMS WHERE id_cms = NEW.id_cms);

        NEW.montant = price;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

/* Pour tester le trigger :

les cartes et leurs proprietaires :
 id_cms | proprietaire | activee | id_personne |    nom     |  prenom   | id_tarif | solde | possede_carte
--------+--------------+---------+-------------+------------+-----------+----------+-------+---------------
      1 |            1 |       1 |           1 | ALMOUZNI   | Geneviève |        1 | 50.00 |             1
      2 |            2 |       0 |           2 | NEWTON     | Isaac     |        2 | 75.00 |             1
      3 |            3 |       1 |           3 | MIRZAKHANI | Maryam    |        3 | 80.00 |             1
      4 |            2 |       1 |           2 | NEWTON     | Isaac     |        2 | 75.00 |             1
      6 |            6 |       0 |           6 | GERMAIN    | Sophie    |        2 | 10.00 |             0
      5 |            4 |       0 |           4 | CELSIUS    | Anders    |        3 | 40.00 |             1
      8 |            4 |       1 |           4 | CELSIUS    | Anders    |        3 | 40.00 |             1
(7 rows)
*/
-- on insère des consommations sans indiquer le montant. La valeur de NEW.montant sera calculée par le trigger.
insert into consommation(id_cms, instant) values (2, current_timestamp) ;
--> ERROR:  carte desactivée

insert into consommation(id_cms, instant) values (3, current_timestamp) ;
--> Ok, le solde de Maryam Mirzakhni passe de 80 à 73.20
--> et le montant de la consommation a bien été calculé à 6.8 (voir table cosommation)

-- on met le solde de Anders Celsius à 2.0
update Personne set solde = 2.0 where id_personne=4;

-- Anders Celsius possède la carte 8, mais il n'a plus assez d'argent pour payer un repas.
insert into consommation(id_cms, instant) values (8, current_timestamp) ;
--> ERROR:  new row for relation "personne" violates check constraint "solde_positif"

----------------
-- Question 3 --
----------------

-- Fonction affichant les consommations par mois d'une personne sur un intervalle donné.
CREATE OR REPLACE FUNCTION afficher_conso(
    start_ DATE,
    end_ DATE,
    id INTEGER
) RETURNS BOOLEAN
AS $$
    DECLARE
        card_ INTEGER;
        month_ record;
    BEGIN
        SELECT possede_carte into card_ FROM Personne WHERE id_personne = id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Personne inconnue';
        END IF;

        FOR month_ IN
            SELECT serie.month AS mois,
                   COALESCE(SUM(c.montant), 0) AS total
            FROM generate_series(
                    date_trunc('month', start_),
                    date_trunc('month', end_),
                    '1 month'::interval
                 ) AS serie(month)
            LEFT JOIN Consommation c ON c.instant between serie.month AND serie.month + INTERVAL '1 month'
            LEFT JOIN CarteMS cms ON c.id_cms = cms.id_cms
            WHERE cms.proprietaire = id
            GROUP BY serie.month
            ORDER BY serie.month

		LOOP
            RAISE NOTICE 'Entre % et % : %',
                month_.mois, month_.mois + INTERVAL '1 month' - INTERVAL '1 second', month_.total;
        END LOOP;

           RETURN card_ = 1;
    END;
$$ LANGUAGE plpgsql;

--pour tester on ajoute quelques consommations :

insert into consommation(id_cms, instant, montant) values (4, current_timestamp - interval '3 months',4.93) ;
insert into consommation(id_cms, instant, montant) values (4, current_timestamp - interval '3 months',4.93) ;

insert into consommation(id_cms, instant, montant) values (4, current_timestamp - interval '2 months',4.93) ;
insert into consommation(id_cms, instant, montant) values (4, current_timestamp - interval '2 months',4.93) ;

insert into consommation(id_cms, instant, montant) values (4, current_timestamp - interval '1 months',4.93) ;

-- consommations de Isaac Newton entre janvier et avril 2022
select afficher_conso('2022-01-12','2022-04-20',2);
--NOTICE:  entre 2022-01-01 00:00:00+01 et 2022-01-31 00:00:00+01 : 9.86
--NOTICE:  entre 2022-02-01 00:00:00+01 et 2022-02-28 00:00:00+01 : 9.86
--NOTICE:  entre 2022-03-01 00:00:00+01 et 2022-03-31 00:00:00+02 : 4.93
--NOTICE:  entre 2022-04-01 00:00:00+02 et 2022-04-30 00:00:00+02 : 0
-- afficher_conso
----------------
-- t
--(1 row)


select afficher_conso('2022-01-12','2022-04-20',3);
--NOTICE:  entre 2022-01-01 00:00:00+01 et 2022-01-31 00:00:00+01 : 0
--NOTICE:  entre 2022-02-01 00:00:00+01 et 2022-02-28 00:00:00+01 : 0
--NOTICE:  entre 2022-03-01 00:00:00+01 et 2022-03-31 00:00:00+02 : 0
--NOTICE:  entre 2022-04-01 00:00:00+02 et 2022-04-30 00:00:00+02 : 6.80
-- afficher_conso
----------------
-- t
--(1 row)

-- exemple avec un mauvais identifiant :
select afficher_conso('2022-01-12','2022-04-20',10);
--ERROR:  personne inconnue

-- exemple avec une personne qui n'a pas actuellement de carte activée :
select afficher_conso('2022-01-12','2022-04-20',6);
--NOTICE:  entre 2022-01-01 00:00:00+01 et 2022-01-31 00:00:00+01 : 0
--NOTICE:  entre 2022-02-01 00:00:00+01 et 2022-02-28 00:00:00+01 : 0
--NOTICE:  entre 2022-03-01 00:00:00+01 et 2022-03-31 00:00:00+02 : 4.93
--NOTICE:  entre 2022-04-01 00:00:00+02 et 2022-04-30 00:00:00+02 : 0
-- afficher_conso
----------------
-- f
--(1 row)
