-- This exmaple illustrates how we can calculate covariance matrix of a given dataset in a very definite manner. In other words, this example is not dimension-agnostic and you have to know the exact number of columns of your dataset before applying this. 
-- author: saif, a. (2k19)

-- define some data (3 dimensional in this case, it can be n-dimensional)
with data as (
  select 1 as a, 2 as b, 3 as c
  union all
  select 12,5,6
  union all
  select 2,8,9
  union all
  select 2,11,12
  union all
  select 3,14,15
  union all
  select 16,17,18
), 
-- pre-establish the length of your dataset
allc as (
  select count(*) allc from data
),
-- pre-establish dimensional means
avgs as (
  select avg(a) as avga, avg(b) as avgb, avg(c) as avgc from data
)

select 
  round(items.f1/allc.allc, 2) as x1, 
  round(items.f2/allc.allc,2) as x2, 
  round(items.f3/allc.allc,2) as x3
from (
  -- since we have 3 dimensions, you see three select statements in here. You can change it based on your dataset to have n of these.
  select 
    struct(sum((a-avgs.avga)*(a-avgs.avga)) as f1, sum((a-avgs.avga)*(b-avgs.avgb)) as f2, sum((a-avgs.avga)*(c-avgs.avgc)) as f3) as items
  from data 
  left join avgs on 1=1

  union all

  select 
    struct(sum((b-avgs.avgb)*(a-avgs.avga)) as f1, sum((b-avgs.avgb)*(b-avgs.avgb)) as f2, sum((b-avgs.avgb)*(c-avgs.avgc)) as f3) as items
  from data 
  left join avgs on 1=1

  union all

  select 
    struct(sum((c-avgs.avgc)*(a-avgs.avga)) as f1, sum((c-avgs.avgc)*(b-avgs.avgb)) as f2, sum((c-avgs.avgc)*(c-avgs.avgc)) as f3) as items
  from data 
  left join avgs on 1=1
)
left join allc on 1=1
