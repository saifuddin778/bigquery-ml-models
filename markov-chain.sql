#standardSQL
/**
* MARKOV CHAIN MODEL (saif, a. - 12/18)
* 
* Markov Chain Models are probabilistic models which rely on the information of single previous state to 
* predict a given discrete state, and can do so N-times, thus able to predict a series of occurrences.
* 
* It can specifically answer questions like: What is the probability of this series of events happening: 
* `no-rain -> rain -> sunny -> cloudy -> rain -> windy`
* or binary events:
* `true -> false -> true -> true -> false -> true`
* 
* In this example, we use one of the publicly available bigquery datasets (`london_bicycles.cycle_hire`) which gives information about 
* bicyle rentals and their `start_station_id` and `end_station_id`. This way, we can (for example) figure out if a bike has an order 
* history of being rented from station 1 and dropped at station 2 , rented from 2 and dropped at 5, rented from 5 and dropped at 4, then where the bike
* will end up if its rented from station 4? 
* 
* Feel free to take this code and modify, bend, whatever to your needs.
*/
with priorcounts as (
  -- prior counts
  -- this is like a table of frequencies:
  -- A, 300 times
  -- B, 200 times 
  --- etc.
  select 
    start_station_id as `from`, 
    count(1) as cnt
  from `bigquery-public-data.london_bicycles.cycle_hire`
  where start_station_id is not null and end_station_id is not null  
  group by 1
  order by 1
),
priorprobs as (
  -- prior probabilities based on prior counts (just probabilities based on priorcounts)
  select `from`, cnt/(select sum(cnt) from priorcounts) as priorprob from priorcounts 
),
data as (
  -- this is the correlation matrix (to say to) linking states and their joint probabilities.
  select 
    t1.from as `from`, 
    t1.to as `to`, 
    t1.ntimes/t2.cnt as `probability`
    from (
      select start_station_id as `from`, end_station_id as `to`, count(1) as ntimes
      from `bigquery-public-data.london_bicycles.cycle_hire`
      where start_station_id is not null and end_station_id is not null 
      group by 1,2
      order by 1,2
    ) t1
    join priorcounts t2 
   on t2.from = t1.from
)
select 
  previous_state,
  current_state, 
  case when previous_state is null then (select priorprob from priorprobs where `from` = current_state) else coalesce(dt.probability, 0.0) end as tt
from (
select
  lag(state) over (partition by 1 order by true) as previous_state,
  state as current_state
from
  #-- THIS is the series of states you want to inquire about.  
  unnest([1,2,2,4,3,3,4]) 
as state
)
left join data dt on dt.from = previous_state and dt.to = current_state
order by 1=1