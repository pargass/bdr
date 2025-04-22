SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-------------------------------------------
-- schéma du discaire : vente d''albums. --
-------------------------------------------

DROP SCHEMA IF EXISTS music CASCADE;
 create schema if not exists music;
 SET schema 'music';

create table album(
  al_id Numeric(4) constraint album_pkey primary key,
  al_titre Varchar(100) not null,
  al_sortie Date
);

create table produit(
  prod_id Numeric(4) constraint produit_pkey primary key,
  prod_al Numeric(4) constraint produit_album_fkey references ALBUM,
  prod_code_barre_ean Varchar(13) not null,
  prod_type_support Varchar(3) -- par exemple 'CD', 'DVD', ou 'Vi' pour vinyle
);

create table facture(
  fac_num Numeric(5) constraint facture_pkey primary key,
  fac_date Date not null,
  fac_montant Numeric(6,2) default 0.0 not null
);

create table ligne_facture(
  lig_produit Numeric(4) constraint ligne_produit_fkey references PRODUIT,
  lig_facture Numeric(5) constraint ligne_facture_fkey references FACTURE,
  lig_prix_vente Numeric(4,2) default 0.0 not null,
  lig_quantite Numeric(2) default 1 not null,
  constraint ligne_facture_pkey primary key(lig_facture, lig_produit)
);


