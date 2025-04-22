-- export PGHOST=webtp.fil.univ-lille.fr
-- psql -U <mon_login>

-- les deux instructions suivantes sont équivalentes
set search_path to music;
set schema 'music';

-- on commence par créer le schéma sans insérer les données

----------
-- Q2.1 --
----------
-- on doit supprimer la clé primaire de facture et recréer la table facture
--\d facture
/*
                    Table "music.facture"
   Column    |     Type     | Collation | Nullable | Default
-------------+--------------+-----------+----------+---------
 fac_num     | numeric(5,0) |           | not null |
 fac_date    | date         |           | not null |
 fac_montant | numeric(6,2) |           | not null | 0.0
Indexes:
    "facture_pkey" PRIMARY KEY, btree (fac_num)
Referenced by:
    TABLE "ligne_facture" CONSTRAINT "ligne_facture_fkey" FOREIGN KEY (lig_facture) REFERENCES facture(fac_num)

*/

alter table facture drop constraint facture_pkey cascade;
--> le cascade entraine la suppression de la clé étrangère entre ligne_facture et facture

-- ou alors
alter table ligne_facture drop constraint ligne_facture_fkey ;
-- on peut ensuite supprimer la table facture et la recréer

drop table facture ;
/*
=> \d facture
                    Table "music.facture"
   Column    |     Type     | Collation | Nullable | Default
-------------+--------------+-----------+----------+---------
 fac_num     | numeric(5,0) |           | not null |
 fac_date    | date         |           | not null |
 fac_montant | numeric(6,2) |           | not null | 0.0
*/

create table facture(
  fac_num Numeric(5), -- sans la clé primaire
  fac_date Date not null,
  fac_montant Numeric(6,2) default 0.0 not NULL
) PARTITION BY RANGE(fac_date);

/*
Si on garde la clé primaire sur fac_num, on a :
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "facture" lacks column "fac_date" which is part of the partition key.

Donc on peut définir un clé primaire mais (fac_num, fac_date)
ce qui assure l'unicité de fac_num à l'intérieur d'une partition mais pas globalement pour toute la table facture


-- il faut créer des tables définies comme fragments de la partition, sinon on ne peut pas insérer :
=> INSERT INTO FACTURE VALUES (101, '2020-01-02', 40.50);
ERREUR:  aucune partition de la relation « facture » trouvée pour la ligne
DETAIL:  La clé de partitionnement de la ligne en échec contient (fac_date) = (2020-01-02).
*/

/*
=> \dt
                  List of relations
 Schema |     Name      |       Type        | Owner
--------+---------------+-------------------+--------
 music  | album         | table             | caronc
 music  | facture       | partitioned table | caronc
 music  | ligne_facture | table             | caronc
 music  | produit       | table             | caronc
(4 rows)

=> \di
                      List of relations
 Schema |        Name        | Type  | Owner  |     Table
--------+--------------------+-------+--------+---------------
 music  | album_pkey         | index | caronc | album
 music  | ligne_facture_pkey | index | caronc | ligne_facture
 music  | produit_pkey       | index | caronc | produit
(3 rows)

donc pas d'index sur facture

*/

create index idx_facture_fac_date on facture(fac_date);
-- music  | idx_facture_fac_date | partitioned index | caronc | facture

----------
-- Q2.2 --
----------
-- nous allons utiliser une fonction stockée qui prend en argument une date et vérifie que
-- la table de la partition correspondant à ce mois existe :
-- si c’est le cas, elle renvoie TRUE,
-- sinon crée la table, affiche un message d’information, puis renvoie TRUE.
-- Nous souhaitons également que lors de la création des tables de la partition un index sur la
-- colonne fac_date soit créé.


/* date_trunc :
The date_trunc function returns a TIMESTAMP or an INTERVAL value.
=> select date_trunc('month',current_date);
date_trunc                   |
-----------------------------+
2024-03-01 00:00:00.000 +0200|

-- alors que to_char renvoie une chaine de caractères
select to_char(current_date,'YYYY_MM');
to_char|
-------+
2024_03|
*/

/*
select relname from pg_class where relname like 'fac%';

create table part_facture_2020_01 partition of facture for values from ('2020-01-01') to ('2020-01-31');
-- la borne inf est inclue, la borne sup exclue
=> INSERT INTO FACTURE VALUES (101, '2020-01-01', 40.50);
INSERT 0 1
=> INSERT INTO FACTURE VALUES (102, '2020-01-31', 23.50);
ERREUR:  aucune partition de la relation « facture » trouvée pour la ligne
DETAIL:  La clé de partitionnement de la ligne en échec contient (fac_date) = (2020-01-31).

drop table part_facture_2020_01 ;

*/
CREATE OR REPLACE FUNCTION verifierPartitionFacture(laDate DATE)
  RETURNS BOOLEAN AS $$
DECLARE
  le_mois CHAR(7) ;
  nom_fragment CHAR(20) ;
  nom_index CHAR(19);
  debut DATE ;
  fin DATE ;
BEGIN
  -- on recherche le mois
  le_mois := to_char(laDate,'YYYY_MM');
  nom_fragment := 'part_facture_'||le_mois;
  nom_index := 'idx_facture_'||le_mois;
  if exists(select relname from pg_class where relname=nom_fragment) then
    -- c'est bon, le fragment de la partition existe pour ce mois_annee
    return true ;
  else
    -- il faut le créer
    debut := date_trunc('month', laDate); -- par exemple 2024-04-01
    fin := debut + INTERVAL '1 month' ;
    EXECUTE 'create table ' || nom_fragment || ' partition of facture for values from '
            || '('''||debut||''') to ('''||fin||''')';

    -- la création de l'index sur la partition est utile si on n'a pas fait un index partitionné sur facture(fac_date)
    -- Execute 'create index '||nom_index||' on '||nom_fragment||'(fac_date)';
    return true ;
  end if;
END;$$
LANGUAGE 'plpgsql';

select verifierPartitionFacture(current_date);

/*
\d+ facture

                                        Partitioned table "music.facture"
   Column    |     Type     | Collation | Nullable | Default | Storage | Compression | Stats target | Description
-------------+--------------+-----------+----------+---------+---------+-------------+--------------+-------------
 fac_num     | numeric(5,0) |           |          |         | main    |             |              |
 fac_date    | date         |           | not null |         | plain   |             |              |
 fac_montant | numeric(6,2) |           | not null | 0.0     | main    |             |              |
Partition key: RANGE (fac_date)
Indexes:
    "idx_facture_fac_date" btree (fac_date)
Partitions: part_facture_2024_03 FOR VALUES FROM ('2024-03-01') TO ('2024-04-01')

*/

----------
-- Q2.3 --
----------
-- Écrivez une fonction stockée qui prend en argument une date et crée les tables pour l’année de cette date.
-- Vous pourrez utiliser avec profit la fonction generate_series de Postgres qui permet de
-- générer des intervalles pour des types donnés.

-- quelques tests sur generate_series et les dates --

SELECT * FROM generate_series('2017-01-01'::DATE, '2017-05-31'::DATE, '1 month');
/*
    generate_series
------------------------
 2017-01-01 00:00:00+00
 2017-02-01 00:00:00+00
 2017-03-01 00:00:00+00
 2017-04-01 00:00:00+00
 2017-05-01 00:00:00+00
(5 rows)
*/

select date_trunc('year', current_date);
/*
      date_trunc
------------------------
 2024-01-01 00:00:00+00
(1 row)
*/
select date_trunc('year', current_date) + INTERVAL '11 month';
/*
       ?column?
------------------------
 2024-12-01 00:00:00+00
(1 row)

*/
select * from generate_series(date_trunc('year', current_date),
                              date_trunc('year', current_date) + INTERVAL '11 month',
                              '1 month');
/*
    generate_series
------------------------
 2024-01-01 00:00:00+00
 2024-02-01 00:00:00+00
 2024-03-01 00:00:00+00
 2024-04-01 00:00:00+00
 2024-05-01 00:00:00+00
 2024-06-01 00:00:00+00
 2024-07-01 00:00:00+00
 2024-08-01 00:00:00+00
 2024-09-01 00:00:00+00
 2024-10-01 00:00:00+00
 2024-11-01 00:00:00+00
 2024-12-01 00:00:00+00
(12 rows)
*/
CREATE OR REPLACE FUNCTION partitionsFactureAnnee(laDate DATE)
  RETURNS BOOLEAN AS $$
DECLARE
  debut DATE;
  fin DATE ;
  d record ;
BEGIN
  debut := date_trunc('year', laDate);
  fin := debut + INTERVAL '11 month';
  for d in (select generate_series as mois from generate_series(debut,fin,'1 month')) loop
     perform verifierPartitionFacture(d.mois::DATE) ; -- le résultat de la fonction ne nous importe pas
  end loop ;
  return TRUE ;
END;$$
LANGUAGE 'plpgsql';

select partitionsFactureAnnee(current_date) ;
/*
partitionsfactureannee
------------------------
 t
(1 row)

exemples=> \d+ facture
                                        Partitioned table "music.facture"
   Column    |     Type     | Collation | Nullable | Default | Storage | Compression | Stats target | Description
-------------+--------------+-----------+----------+---------+---------+-------------+--------------+-------------
 fac_num     | numeric(5,0) |           |          |         | main    |             |              |
 fac_date    | date         |           | not null |         | plain   |             |              |
 fac_montant | numeric(6,2) |           | not null | 0.0     | main    |             |              |
Partition key: RANGE (fac_date)
Indexes:
    "idx_facture_fac_date" btree (fac_date)
Partitions: part_facture_2024_01 FOR VALUES FROM ('2024-01-01') TO ('2024-02-01'),
            part_facture_2024_02 FOR VALUES FROM ('2024-02-01') TO ('2024-03-01'),
            part_facture_2024_03 FOR VALUES FROM ('2024-03-01') TO ('2024-04-01'),
            part_facture_2024_04 FOR VALUES FROM ('2024-04-01') TO ('2024-05-01'),
            part_facture_2024_05 FOR VALUES FROM ('2024-05-01') TO ('2024-06-01'),
            part_facture_2024_06 FOR VALUES FROM ('2024-06-01') TO ('2024-07-01'),
            part_facture_2024_07 FOR VALUES FROM ('2024-07-01') TO ('2024-08-01'),
            part_facture_2024_08 FOR VALUES FROM ('2024-08-01') TO ('2024-09-01'),
            part_facture_2024_09 FOR VALUES FROM ('2024-09-01') TO ('2024-10-01'),
            part_facture_2024_10 FOR VALUES FROM ('2024-10-01') TO ('2024-11-01'),
            part_facture_2024_11 FOR VALUES FROM ('2024-11-01') TO ('2024-12-01'),
            part_facture_2024_12 FOR VALUES FROM ('2024-12-01') TO ('2025-01-01')

*/


-- Utilisez la fonction que vous venez d’écrire pour créer les tables de la partition pour l’année 2020.
-- Testez votre configuration à l’aide des entrées dans la suite du fichier.
-- Si vous n’avez pas d’erreur à l’insertion, vérifiez tout de même que les données sont bien présentes avec quelques requêtes.
select partitionsFactureAnnee('2020-03-15') ;

--> je fais les insert dans Facture, ça marche
select count(*) from facture;
/*
 count
-------
  2032
(1 row)
*/

select count(*) from part_facture_2020_04 ;
/*
 count
-------
   187
(1 row)
*/

/* Schema avec les indexes :
=> \dt+
                                                  List of relations
 Schema |         Name         |       Type        | Owner  | Persistence | Access method |    Size    | Description
--------+----------------------+-------------------+--------+-------------+---------------+------------+-------------
 music  | album                | table             | caronc | permanent   | heap          | 8192 bytes |
 music  | facture              | partitioned table | caronc | permanent   |               | 0 bytes    |
 music  | ligne_facture        | table             | caronc | permanent   | heap          | 232 kB     |
 music  | part_facture_2020_01 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_02 | table             | caronc | permanent   | heap          | 8192 bytes |
 music  | part_facture_2020_03 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_04 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_05 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_06 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_07 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_08 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_09 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_10 | table             | caronc | permanent   | heap          | 8192 bytes |
 music  | part_facture_2020_11 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2020_12 | table             | caronc | permanent   | heap          | 40 kB      |
 music  | part_facture_2024_01 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_02 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_03 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_04 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_05 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_06 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_07 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_08 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_09 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_10 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_11 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | part_facture_2024_12 | table             | caronc | permanent   | heap          | 0 bytes    |
 music  | produit              | table             | caronc | permanent   | heap          | 8192 bytes |
(28 rows)


=> \di
                                      List of relations
 Schema |               Name                |       Type        | Owner  |        Table
--------+-----------------------------------+-------------------+--------+----------------------
 music  | album_pkey                        | index             | caronc | album
 music  | idx_facture_fac_date              | partitioned index | caronc | facture
 music  | ligne_facture_pkey                | index             | caronc | ligne_facture
 music  | part_facture_2020_01_fac_date_idx | index             | caronc | part_facture_2020_01
 music  | part_facture_2020_02_fac_date_idx | index             | caronc | part_facture_2020_02
 music  | part_facture_2020_03_fac_date_idx | index             | caronc | part_facture_2020_03
 music  | part_facture_2020_04_fac_date_idx | index             | caronc | part_facture_2020_04
 music  | part_facture_2020_05_fac_date_idx | index             | caronc | part_facture_2020_05
 music  | part_facture_2020_06_fac_date_idx | index             | caronc | part_facture_2020_06
 music  | part_facture_2020_07_fac_date_idx | index             | caronc | part_facture_2020_07
 music  | part_facture_2020_08_fac_date_idx | index             | caronc | part_facture_2020_08
 music  | part_facture_2020_09_fac_date_idx | index             | caronc | part_facture_2020_09
 music  | part_facture_2020_10_fac_date_idx | index             | caronc | part_facture_2020_10
 music  | part_facture_2020_11_fac_date_idx | index             | caronc | part_facture_2020_11
 music  | part_facture_2020_12_fac_date_idx | index             | caronc | part_facture_2020_12
 music  | part_facture_2024_01_fac_date_idx | index             | caronc | part_facture_2024_01
 music  | part_facture_2024_02_fac_date_idx | index             | caronc | part_facture_2024_02
 music  | part_facture_2024_03_fac_date_idx | index             | caronc | part_facture_2024_03
 music  | part_facture_2024_04_fac_date_idx | index             | caronc | part_facture_2024_04
 music  | part_facture_2024_05_fac_date_idx | index             | caronc | part_facture_2024_05
 music  | part_facture_2024_06_fac_date_idx | index             | caronc | part_facture_2024_06
 music  | part_facture_2024_07_fac_date_idx | index             | caronc | part_facture_2024_07
 music  | part_facture_2024_08_fac_date_idx | index             | caronc | part_facture_2024_08
 music  | part_facture_2024_09_fac_date_idx | index             | caronc | part_facture_2024_09
 music  | part_facture_2024_10_fac_date_idx | index             | caronc | part_facture_2024_10
 music  | part_facture_2024_11_fac_date_idx | index             | caronc | part_facture_2024_11
 music  | part_facture_2024_12_fac_date_idx | index             | caronc | part_facture_2024_12
 music  | produit_pkey                      | index             | caronc | produit
(28 rows)

Les index se sont créés automatiquement sur chaque partition. indexes sur fac_date


=> \di+ part_facture_2020_03_fac_date_idx
                                                    List of relations
 Schema |               Name                | Type  | Owner  |        Table         | Persistence | Access method | Size  | Description
--------+-----------------------------------+-------+--------+----------------------+-------------+---------------+-------+-------------
 music  | part_facture_2020_03_fac_date_idx | index | caronc | part_facture_2020_03 | permanent   | btree         | 16 kB |
(1 row)

*/

-- remarque : la question 2.4 a l'air de justifier la solution de tables attachées a posteriori par la possibilité de définir une clé primaire sur fac_num locale à chaque fragment.
-- en fait c'est déjà possible :
alter table part_facture_2020_01 add constraint part_facture_2020_01_pkey primary key(fac_num);
alter table part_facture_2020_02 add constraint part_facture_2020_02_pkey primary key(fac_num);
alter table part_facture_2020_03 add constraint part_facture_2020_03_pkey primary key(fac_num);
alter table part_facture_2020_04 add constraint part_facture_2020_04_pkey primary key(fac_num);
alter table part_facture_2020_05 add constraint part_facture_2020_05_pkey primary key(fac_num);
alter table part_facture_2020_06 add constraint part_facture_2020_06_pkey primary key(fac_num);
alter table part_facture_2020_07 add constraint part_facture_2020_07_pkey primary key(fac_num);
alter table part_facture_2020_08 add constraint part_facture_2020_08_pkey primary key(fac_num);
alter table part_facture_2020_09 add constraint part_facture_2020_09_pkey primary key(fac_num);
alter table part_facture_2020_10 add constraint part_facture_2020_10_pkey primary key(fac_num);
alter table part_facture_2020_11 add constraint part_facture_2020_11_pkey primary key(fac_num);
alter table part_facture_2020_12 add constraint part_facture_2020_12_pkey primary key(fac_num);

/*
-- on a maintenant un index partitionné sur facture(fac_date) et 12 indexes sur fac_num pour les 12 fragments de la partition
 music  | idx_facture_fac_date              | partitioned index | caronc | facture              | permanent   | btree         | 0 bytes |
 music  | part_facture_2020_01_fac_date_idx | index             | caronc | part_facture_2020_01 | permanent   | btree         | 16 kB   |
 music  | part_facture_2020_01_pkey         | index             | caronc | part_facture_2020_01 | permanent   | btree         | 16 kB   |
...

*/
----------
-- Q2.4 --
----------
-- seconde solution en créant des tables "autonomes" et en les attachant à la table facture en tant que fragment de la partition
CREATE OR REPLACE FUNCTION verifierPartitionFacture(laDate DATE)
  RETURNS BOOLEAN AS $$
DECLARE
  le_mois CHAR(7) ;
  nom_fragment CHAR(20) ;
  nom_index CHAR(19);
  debut DATE ;
  fin DATE ;
BEGIN
  -- on recherche le mois
  le_mois := to_char(laDate,'YYYY_MM');
  nom_fragment := 'part_facture_'||le_mois;
  nom_index := 'idx_facture_'||le_mois;
  if exists(select relname from pg_class where relname=nom_fragment) then
    -- c'est bon, le fragment de la partition existe pour ce mois_annee
    return true ;
  else
    -- il faut le créer
    debut := date_trunc('month', laDate); -- par exemple 2024-03-01
    fin := debut + interval '1 month' ;
    Execute 'create table ' || nom_fragment ||'(fac_num Numeric(5) primary key,'
                                            ||'fac_date Date not null,'
                                            ||'fac_montant Numeric(6,2) default 0.0 not null) ';

    Execute 'alter table facture attach partition ' || nom_fragment || ' for values from '
            || '(''' || debut || ''') to (''' || fin || ''')';
    -- idem, inutile si deja index sur facture(fac_date)
    --Execute 'create index '||nom_index||' on '||nom_fragment||'(fac_date)';
    return true ;
  end if;
END;$$
LANGUAGE 'plpgsql';

-- je teste en supprimant l'ancienne partition'
drop table facture ;

create table facture(
  fac_num Numeric(5),  -- pas de clé primaire
  fac_date Date not null,
  fac_montant Numeric(6,2) default 0.0 not NULL
) PARTITION BY RANGE(fac_date);

create index idx_facture_fac_date on facture(fac_date);


select partitionsFactureAnnee('2020-03-15') ;

/*
=> \d+ facture
    Partitioned table "music.facture"
   Column    |     Type     | Collation | Nullable | Default | Storage | Compression | Stats target | Description
-------------+--------------+-----------+----------+---------+---------+-------------+--------------+-------------
 fac_num     | numeric(5,0) |           |          |         | main    |             |              |
 fac_date    | date         |           | not null |         | plain   |             |              |
 fac_montant | numeric(6,2) |           | not null | 0.0     | main    |             |              |
Partition key: RANGE (fac_date)
Indexes:
    "idx_facture_fac_date" btree (fac_date)
Partitions: part_facture_2020_01 FOR VALUES FROM ('2020-01-01') TO ('2020-02-01'),
            part_facture_2020_02 FOR VALUES FROM ('2020-02-01') TO ('2020-03-01'),
            part_facture_2020_03 FOR VALUES FROM ('2020-03-01') TO ('2020-04-01'),
            part_facture_2020_04 FOR VALUES FROM ('2020-04-01') TO ('2020-05-01'),
            part_facture_2020_05 FOR VALUES FROM ('2020-05-01') TO ('2020-06-01'),
            part_facture_2020_06 FOR VALUES FROM ('2020-06-01') TO ('2020-07-01'),
            part_facture_2020_07 FOR VALUES FROM ('2020-07-01') TO ('2020-08-01'),
            part_facture_2020_08 FOR VALUES FROM ('2020-08-01') TO ('2020-09-01'),
            part_facture_2020_09 FOR VALUES FROM ('2020-09-01') TO ('2020-10-01'),
            part_facture_2020_10 FOR VALUES FROM ('2020-10-01') TO ('2020-11-01'),
            part_facture_2020_11 FOR VALUES FROM ('2020-11-01') TO ('2020-12-01'),
            part_facture_2020_12 FOR VALUES FROM ('2020-12-01') TO ('2021-01-01')

=>\di
 Schema |               Name                |       Type        | Owner  |        Table
--------+-----------------------------------+-------------------+--------+----------------------
 music  | album_pkey                        | index             | caronc | album
 music  | idx_facture_fac_date              | partitioned index | caronc | facture
 music  | ligne_facture_pkey                | index             | caronc | ligne_facture
 music  | part_facture_2020_01_fac_date_idx | index             | caronc | part_facture_2020_01
 music  | part_facture_2020_01_pkey         | index             | caronc | part_facture_2020_01
 music  | part_facture_2020_02_fac_date_idx | index             | caronc | part_facture_2020_02
 music  | part_facture_2020_02_pkey         | index             | caronc | part_facture_2020_02
 music  | part_facture_2020_03_fac_date_idx | index             | caronc | part_facture_2020_03
 music  | part_facture_2020_03_pkey         | index             | caronc | part_facture_2020_03
 music  | part_facture_2020_04_fac_date_idx | index             | caronc | part_facture_2020_04
 music  | part_facture_2020_04_pkey         | index             | caronc | part_facture_2020_04
 music  | part_facture_2020_05_fac_date_idx | index             | caronc | part_facture_2020_05
 music  | part_facture_2020_05_pkey         | index             | caronc | part_facture_2020_05
 music  | part_facture_2020_06_fac_date_idx | index             | caronc | part_facture_2020_06
 music  | part_facture_2020_06_pkey         | index             | caronc | part_facture_2020_06
 music  | part_facture_2020_07_fac_date_idx | index             | caronc | part_facture_2020_07
 music  | part_facture_2020_07_pkey         | index             | caronc | part_facture_2020_07
 music  | part_facture_2020_08_fac_date_idx | index             | caronc | part_facture_2020_08
 music  | part_facture_2020_08_pkey         | index             | caronc | part_facture_2020_08
 music  | part_facture_2020_09_fac_date_idx | index             | caronc | part_facture_2020_09
 music  | part_facture_2020_09_pkey         | index             | caronc | part_facture_2020_09
 music  | part_facture_2020_10_fac_date_idx | index             | caronc | part_facture_2020_10
 music  | part_facture_2020_10_pkey         | index             | caronc | part_facture_2020_10
 music  | part_facture_2020_11_fac_date_idx | index             | caronc | part_facture_2020_11
 music  | part_facture_2020_11_pkey         | index             | caronc | part_facture_2020_11
 music  | part_facture_2020_12_fac_date_idx | index             | caronc | part_facture_2020_12
 music  | part_facture_2020_12_pkey         | index             | caronc | part_facture_2020_12
 music  | produit_pkey                      | index             | caronc | produit
(28 rows)


*/

-- les insertions marchent bien, on a les mêmes volumes que pour la question précédente
select count(*) from facture;
/*
 count
-------
  2032
(1 row)
*/

select count(*) from part_facture_2020_04 ;
/*
 count
-------
   187
(1 row)
*/

----------
-- Q2.5 --
----------
-- Afin de conserver une bonne performance de la base de données, on souhaite
--ne conserver que les factures des six derniers mois. Vous allez pour cela écrire une fonction
--stockée qui détache les partitions de plus de six mois qui composent la table facture.

-- pour une fois, je fais une fonction avec le langage SQL et pas plpgsql.
-- La fonction suivante génère un tableau de chaines de caractères
-- qui contient les noms de fragments qui correspondent à l'intervalle de date debut-fin.
create or replace function tableNomFragments(debut DATE, fin DATE)
returns table(nom_fragment Varchar(30)) as $$
  select 'part_facture_'||to_char(generate_series,'YYYY_MM') as nom_fragment from generate_series(debut,fin,'1 month');
$$
LANGUAGE 'sql';

-- exemple de résultat de cette fonction ; date de référence au 16 avril 2021
select * from tableNomFragments(
  (date_trunc('month',to_date('2021-04-16','YYYY-MM-DD')) - INTERVAL '6 month')::date,
  date_trunc('month',to_date('2021-04-16','YYYY-MM-DD'))::date
  );

/*
     nom_fragment
----------------------
 part_facture_2020_10
 part_facture_2020_11
 part_facture_2020_12
 part_facture_2021_01
 part_facture_2021_02
 part_facture_2021_03
 part_facture_2021_04
(7 rows)

*/

/*
=> select relname,relispartition
from pg_class where relispartition;

              relname              | relispartition
-----------------------------------+----------------
 part_facture_2020_01              | t
 part_facture_2020_01_fac_date_idx | t
 part_facture_2020_02              | t
 part_facture_2020_02_fac_date_idx | t
 part_facture_2020_03              | t
 part_facture_2020_03_fac_date_idx | t
 part_facture_2020_04              | t
 part_facture_2020_04_fac_date_idx | t
 part_facture_2020_05              | t
 part_facture_2020_05_fac_date_idx | t
 part_facture_2020_06              | t
 part_facture_2020_06_fac_date_idx | t
 part_facture_2020_07              | t
 part_facture_2020_07_fac_date_idx | t
 part_facture_2020_08              | t
 part_facture_2020_08_fac_date_idx | t
 part_facture_2020_09              | t
 part_facture_2020_09_fac_date_idx | t
 part_facture_2020_10              | t
 part_facture_2020_10_fac_date_idx | t
 part_facture_2020_11              | t
 part_facture_2020_11_fac_date_idx | t
 part_facture_2020_12              | t
 part_facture_2020_12_fac_date_idx | t
(24 rows)

*/

CREATE OR REPLACE FUNCTION menagePartitionFacture(date_de_reference DATE default current_date)
  RETURNS BOOLEAN AS $$
DECLARE
  mois_courant DATE ;
  limite DATE ;
  r record ;
BEGIN
  mois_courant := date_trunc('month',date_de_reference);
  limite := mois_courant - INTERVAL '6 month'; -- on va garder entre 6 et 7 mois
  raise notice 'mois courant : % et date limite : % ',mois_courant, limite ;
  for r in (select relname from pg_class where relispartition
    and relname like 'part_facture_%'
    and relname not like '%_fac_date_idx'
    and relname < 'part_facture_'||to_char(limite,'YYYY_MM')) loop
    -- on peut aussi dire - mais c'est plus couteux - à la place de la dernière condition :
    -- and relname not in (select * from tableNomFragments(limite,mois_courant))
        raise notice 'fragment détaché : %',r.relname ;
        Execute 'alter table facture detach partition '  || r.relname;
  end loop ;
  return TRUE ;
END;$$
LANGUAGE 'plpgsql';

select menagePartitionFacture(to_date('2021-04-16','YYYY-MM-DD'));
/*
NOTICE:  mois courant : 2021-04-01 et date limite : 2020-10-01
NOTICE:  fragment détaché : part_facture_2020_01
NOTICE:  fragment détaché : part_facture_2020_02
NOTICE:  fragment détaché : part_facture_2020_03
NOTICE:  fragment détaché : part_facture_2020_04
NOTICE:  fragment détaché : part_facture_2020_05
NOTICE:  fragment détaché : part_facture_2020_06
NOTICE:  fragment détaché : part_facture_2020_07
NOTICE:  fragment détaché : part_facture_2020_08
NOTICE:  fragment détaché : part_facture_2020_09
 menagepartitionfacture
------------------------
 t
(1 row)

*/

/*
\d+ facture
                                       Partitioned table "music.facture"
   Column    |     Type     | Collation | Nullable | Default | Storage | Compression | Stats target | Description
-------------+--------------+-----------+----------+---------+---------+-------------+--------------+-------------
 fac_num     | numeric(5,0) |           |          |         | main    |             |              |
 fac_date    | date         |           | not null |         | plain   |             |              |
 fac_montant | numeric(6,2) |           | not null | 0.0     | main    |             |              |
Partition key: RANGE (fac_date)
Indexes:
    "idx_facture_fac_date" btree (fac_date)
Partitions: part_facture_2020_10 FOR VALUES FROM ('2020-10-01') TO ('2020-11-01'),
            part_facture_2020_11 FOR VALUES FROM ('2020-11-01') TO ('2020-12-01'),
            part_facture_2020_12 FOR VALUES FROM ('2020-12-01') TO ('2021-01-01')


Les tables partitions existent toujours mais elles sont détachées.
Les index existent toujours
*/


--On peut supprimer les partitions détachées
=>drop table part_facture_2020_01;

-- on peut aussi supprimer les partitions non détachées ...
=>drop table part_facture_2020_11;
DROP TABLE
=> select count(*) from facture;
/*
 count
-------
   339
(1 row)

ça correspond à octobre + décembre
=> select count(*) from part_facture_2020_12;
 count
-------
   193

=> select count(*) from part_facture_2020_10;
 count
-------
   146

=> select relname,relispartition
from pg_class where relispartition;
              relname              | relispartition
-----------------------------------+----------------
 part_facture_2020_10              | t
 part_facture_2020_10_fac_date_idx | t
 part_facture_2020_12              | t
 part_facture_2020_12_fac_date_idx | t
(4 rows)

=> \dt+ facture
                                          List of relations
 Schema |  Name   |       Type        | Owner  | Persistence | Access method |  Size   | Description
--------+---------+-------------------+--------+-------------+---------------+---------+-------------
 music  | facture | partitioned table | caronc | permanent   |               | 0 bytes |
(1 row)

Sur DBeaver je vois que part_facture_2020_10 et part_facture_2020_12 sont bien des partitions de Facture
part_facture_2020_09 est une table "normale" puisqu'elle a été détachée de la table facture.

*/

----------
-- Q2.6 --
----------
-- On peut écrire un script et l'enregistrer sur la crontab du serveur pour se déclencher chaque mois.
-- Ce script interagit avec la base de données pour
-- 1. déclencher la fonction de la question 2.5 et
-- 2. récupérer la liste des partitions détachée.
-- Il fait ensuite un dump pour chaque table détachée (via le shell).
-- Enfin il interagit de nouveau avec la base pour effacer les tables de la base de données.


