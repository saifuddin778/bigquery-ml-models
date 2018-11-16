-- training a simple naive bayesian model in sql to generate predictions. 
-- here we demo by ctes, but you can always create these tables and query those to get faster results.
-- data being utilized is bq's publicly available `bigquery-public-data.samples.natality` dataset.
-- saif, a.
-- 11/2018
with data as ( 
  select 
    to_hex(md5(cast(ceil(rand()) * rand() as string))) as name,
    coalesce(state, 'N/A') as state,
    case when is_male then 'male' else 'female' end as gender,
    case when cigarette_use then 'smoker' else 'non-smoker' end as smokery,
    case when alcohol_use then 'drinker' else 'non-drinker' end as drinkery
    from `bigquery-public-data.samples.natality`
),
countall as ( 
  select count(1) as cnt 
  from data 
),
pprobs as (
  select key, n_items/c.cnt as prob from (
  select d.state as key, count(1) as n_items
  from data d
  group by 1
 )
 join countall c on 1 = 1
),
pevidence as (
  with gender_metrics as ( 
    select gender as key, 'gender' as type, count(1) as n_items from data group by 1 
  ),
  smokery_metrics as ( 
    select smokery as key, 'smokery' as type, count(1) as n_items from data group by 1 
  ),
  drinkery_metrics as ( 
    select drinkery as key, 'drinkery' as type, count(1) as n_items from data group by 1 
  ),
  combined as (
    select * from (select * from gender_metrics)
    union all
    select * from (select * from smokery_metrics)
    union all
    select * from (select * from drinkery_metrics)
  )
  select cmb.key, cmb.type, cmb.n_items/c.cnt as prob from combined cmb
  join countall c on 1 = 1
),
plikelyhood as (
  select state as key, gender, smokery, drinkery, count(1) as n_items 
  from data
  group by 1,2,3,4
)
--ex: querying probability of a sample being from `NY`, given that he is a `male` and a `smoker`.
select
(
  select sum(IF(key = 'NY' and gender = 'male', n_items, 0))/sum(IF(key = 'NY', n_items, 0)) * 
  sum(IF(key = 'NY' and smokery = 'smoker', n_items, 0))/sum(IF(key = 'NY', n_items, 0)) * 
  sum(IF(key = 'NY' and drinkery = 'NY', n_items, 0))/sum(IF(key = 'NY', n_items, 0)) * 
  (select prob from pprobs where key = 'NY') 
  from plikelyhood
)
/
(
 select
   sum(if(type = 'gender' and key = 'male', prob, 0)) *
  sum(if(type = 'smokery' and key = 'smoker', prob, 0)) * 
  sum(if(type = 'drinkery' and key = 'drinker', prob, 0)) from pevidence
)