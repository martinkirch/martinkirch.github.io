


```sql
select min(weight), max(weight), avg(weight), stddev(weight) from lexicon.keyword ;
 min | max  |       avg        |      stddev
-----+------+------------------+------------------
   0 | 8419 | 1.41718822979916 | 28.1351262297869
```

looks good!


## Look at your data, they say





## SQL (and more statistics) to the rescue

If you can't quickly draw a histogram, statistic has some other interesting 
tools:
(median)[https://en.wikipedia.org/wiki/Median] or, 
much better, (decile)[https://en.wikipedia.org/wiki/Decile]
and (percentile)[https://en.wikipedia.org/wiki/Percentile].

The SQL standard introduced (in a 200X edition) the `PERCENTILE_CONT` operator,
which can compute any percentile (and therefore also the median, decile, quartile...)
of a distribution, over a complete table or a sub-group.

(Oracle documentation)[http://docs.oracle.com/cd/B19306_01/server.102/b14200/functions110.htm]
provides a concise and precise definition 

> PERCENTILE_CONT is an inverse distribution function that assumes a continuous distribution model. It takes a percentile value and a sort specification, and returns an interpolated value that would fall into that percentile value with respect to the sort specification. Nulls are ignored in the calculation.







But in PostGres9.4 and up we have ordered-set aggregates which means we can find 
deciles or median.

https://www.depesz.com/2014/01/11/waiting-for-9-4-support-ordered-set-within-group-aggregates/

```sql
SELECT PERCENTILE_CONT(array[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]) WITHIN GROUP(ORDER by weight) FROM lexicon.keyword;
   percentile_cont
---------------------
 {0,0,0,0,0,0,1,1,2}
```
