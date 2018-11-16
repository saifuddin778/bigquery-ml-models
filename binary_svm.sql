-- this example trains a standard binary support vector machine 
-- model using a small fake dataset. Its using external UDF, but good point 
-- is bq's potentially `unlimited` resource to power the thing.
-- saif, a.
-- 11/2018
CREATE TEMPORARY FUNCTION train(data Array< STRUCT<x float64, y float64, label int64>>)
  RETURNS array<float64>
    LANGUAGE js AS """
    var weights = Array(3).fill(Math.random() * 2);
    var l = data.length;
    var step_size = 0.001;
    for (var i=0; i<500; i++) {
      var index = parseInt(Math.random() * l);
      var x = data[index].x;
      var y = data[index].y;
      var label = data[index].label;
      var score = weights[0]*x + weights[1]*y + weights[2];
      var pull = 0.0;
      if(label === 1 && score < 1){
        pull = 1;
      };
      if(label === -1 && score > -1){
        pull = -1;
      };
    
      weights[0] += step_size * ((x * pull) - weights[0]);
      weights[1] += step_size * ((y * pull) - weights[1]);
      weights[2] += step_size * (1 * pull);
    };
    return weights;
""";
with data as (
  SELECT array_agg(struct(x as x, y as y, label as label)) as d from (
    select x, y, label from unnest(
    ARRAY
      (
        SELECT AS STRUCT 1.2 x, 0.7 y, 1 label
        UNION ALL 
        SELECT AS STRUCT -0.3 x, -0.5 y, -1 label
        union all
        select as struct 3.0 x, 0.1 y, 1 label
        union all 
        select as struct -0.1 x, -1.0 y, -1 label
        union all
        select as struct -1.0 x, 1.1 y, -1 label
        union all
        select as struct 2.1 x, -3.0 y, 1 label
        ))
  )),
weights as (
  select train(d) as w from data
)
select * from weights