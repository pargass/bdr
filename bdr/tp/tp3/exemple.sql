-- exemple de fonction avec le langage SQL, et pas PLpgSQL.
-- cette fonction prend une date en paramètre et renvoie le nombre entre 1 et 12 qui correspond au mois.
CREATE OR REPLACE FUNCTION le_mois(d date)
  RETURNS numeric
AS
$$
  select to_number(to_char(d,'MM'),'99');
$$
LANGUAGE sql
IMMUTABLE; --> ne pas changer de fuseau horaire dans le contexte d'exécution de la fonction

-- cette fonction apporte une solution au problème rencontré lors du TD sur les index.

-- sur notre schéma 'music' :
create index factures_par_mois_hash on facture using hash(le_mois(fac_date)) ;
-- peu importe, on peut créer un index hash ou btree

-- il faut utiliser le_mois dans les requêtes pour que l'index soit utilisé
explain analyze
select * from facture
where le_mois(fac_date) = 4; -- factures du mois d'avril