-- Transaction produisant un échantillon de données pour la base de
-- données clients

begin ;

INSERT INTO clients
values ('MonPay' ,'8, rue de la soupe, 83120 Douby Sur Var' ) --,'t')
       ,('Société Particulière' ,'93, avenue Alponse Douillard, 95320 La Crue') --,'t')
       ,('SPLFBC' ,'Cité Oudrot, 57110 Loupsse') --,'t')
       ,('ENVREDS' ,'rue des affranchis, 31560 Ruhet') --,'t')
       ,('La Côtée', '7 impasse des Marsouins, 56501 Languidec') --,'t')
       ,('Enrier', 'Zone des Rutauts, 60120 Fyrec') --,'t')
       ,('S.T.E.R.E.G', '2 rue des Incas, 25340 St-Anois') --,'t')
       ,('FREC-TIS', 'Le bourg, 15230 Adurac') --,'t')
;

INSERT INTO contacts
values ('Damien'    , 'Testet'      , '0409443135' , 'dtestet@monpay.biz'        , 'Acheteur'   , 'MonPay' )
      ,('Thérèse'   , 'Androt'      , '0409443154' , 'tandrot@monpay.biz'        , 'Comptable'  , 'MonPay' )
      ,('Damien'    , 'Lendrot'     , '0109323132' , 'dlandrot@sp.com.biz'       , 'Acheteur'   , 'Société Particulière' )
      ,('Sophie'    , 'Estère'      , '0109323138' , 'sestere@sp.com.biz'        , 'Comptable ' , 'Société Particulière' )
      ,('Vincent'   , 'Aspic'       , '0309653176' , 'vaspic@splfbc.fr'          , 'Acheteur'   , 'SPLFBC' )
      ,('Caroline'  , 'Lenpuis'     , '0309653143' , 'clenpuis@splfbc.fr'        , 'Comptable'  , 'SPLFBC' )
      ,('Antoine'   , 'Ramier'      , '0509323198' , 'aramier@envreds.org'       , 'Acheteur'   , 'ENVREDS' )
      ,('Astrid'    , 'Neliera'     , '0509323943' , 'aneliera@envreds.org'      , 'Comptable'  , 'ENVREDS' )
      ,('Joachim'   , 'Deruche'     , '0243659165' , 'jderuche@la-cotee.coop'    , 'Acheteur'   , 'La Côtée' )
      ,('Anne'      , 'Lordet'      , '0243659143' , 'alordet@la-cotee.coop'     , 'Comptable'  , 'La Côtée' )
      ,('Henry'     , 'Passeda'     , '0512658303' , 'hpasseda@enrier.fr'        , 'Acheteur'   ,'Enrier' )
      ,('Véronique' , 'Leto'        , '0512658305' , 'vleto@enrier.fr'           , 'Comptable'  ,'Enrier' )
      ,('Charles'   , 'D''Herrier'  , '0354219420' , 'cdherrier@stereg.fr'       , 'Acheteur'   ,'S.T.E.R.E.G' )
      ,('Madelaine' , 'Hercot'      , '0354219420' , 'mhercot@stereg.fr'         , 'Comptable'  ,'S.T.E.R.E.G' )
      ,('Piotr'     , 'Zurca'       , '0554016279' , 'pzurca@frec-tis.com'       , 'Acheteur'   ,'FREC-TIS' )
      ,('Clémence'  , 'Dechanville' , '0554016279' , 'cdechanville@frec-tis.com' , 'Comptable'  , 'FREC-TIS' )
;

INSERT INTO prestations
with dates as (
select cl_nom, x + ( (random() * 10)::int * '1d'::interval ) as date_debut
     from clients, generate_series('1970-01-01'::date, current_date, '1w'::interval) x
),
datesf as (
select cl_nom, date_debut, date_debut + ((random() * 4)::int + 1) * '1d'::interval as date_fin  from dates
),
prest as (
select * from (values ('Maintenance'),('Livraison'),('Enlevement'),('Autre'),('Consultation')) as t -- ,('Formation')
),
datas as (
select row_number() over () as id, column1 as intitule,
    'Entrer ici la description de la prestation' as description,
    upper(substring(column1 from 1 for 1)) as type, date_debut, date_fin,
    case when random() < 0.1 then 'f'::boolean else 't'::boolean end, cl_nom
    from datesf, prest
    order by random()
)
select * from datas order by id
;

INSERT INTO factures
with dates as (
select distinct x + ( (random() * 10)::int * '1d'::interval ) as fact_date, cl_nom
   from clients, generate_series('1970-01-01'::date, current_date, '1mon'::interval) x
   order by 1, 2
   )
select ltrim(to_char( row_number() over (), '00000') || upper(substring(cl_nom from 1 for 1))) as num,
       fact_date, fact_date + '1mon'::interval + (random()*10)*'1d'::interval as date_paiement,
       case when random() < 0.5 then 'C' else 'V' end  as moyen_paiement, cl_nom
       from dates
;

INSERT INTO lignes_factures
with facts as (
select fact_num, cl_nom, fact_date, lag( fact_date ) over (partition by cl_nom order by fact_date ) dprev from factures
)
select fact_num, prest_id, prest_intitule,
       (case when prest_intitule = 'Maintenance' then 600
             when prest_intitule = 'Consultation' then 700 else 400 end) - ( (current_date - prest_date_fin::date) / 250) as montant, 1
    from prestations join facts on prest_date_fin > dprev and prest_date_fin < fact_date and facts.cl_nom = prestations.cl_nom
;

-- REFRESH MATERIALIZED VIEW facturation ;

commit;
