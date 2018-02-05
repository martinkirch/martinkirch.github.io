title: Quickly guess your data's distribution with PostGreSQL
briefing: Given a million scores, how to quickly have an idea of their distribution?
date_time: 2018-02-05 20:00
slug: distribution-discovery-with-postgres
tags: data, postgres, statistics
type: post

In this post we get back to basics!

When designing a scoring function we quickly need to know how scores are distributed
over our data. The distribution you need of course depends on the final purpose
of the scoring function. But wether it's for ordering or for selecting rows
above/below some threshold, in all cases a few Postgres functions are enough
to get an overview of your scores' distribution.
These can be faster and simpler than plotting, especially when working with millions of rows.


## Well-known statistics

Let's say we assigned a `score` to all rows in our `tags` table.
To assess that this score is well-distributed among thousands or millions of rows,
the first thing that comes to mind can be the four classics: 
minimum, maximum, average and standard deviation.

    SELECT min(score), max(score), avg(score), stddev(score) FROM tags ;
    
     min | max  |       avg        |      stddev
    -----+------+------------------+------------------
       0 | 8419 | 1.41718822979916 | 28.1351262297869

But from here it's hard to tell if `score` will fit any usage,
this just tells us the range and precision we can expect when manipulating `score`.
A standard deviation so much greater than the average is surprising, though. 
Its meaning will get clearer with another method.


## The hurried programmer's histogram

Other statistic functions are interesting in this case,
because they can be as informative as an histogram: 
[median](https://en.wikipedia.org/wiki/Median) or, 
much better, [decile](https://en.wikipedia.org/wiki/Decile)
and [percentile](https://en.wikipedia.org/wiki/Percentile).

The SQL standard introduced (in a 200X edition) the `PERCENTILE_CONT` operator,
which can compute any percentile (thus including median, decile, quartile...)
of a distribution, over a complete table or a sub-group.
Here is the precise definition from the 
[Oracle documentation](http://docs.oracle.com/cd/B19306_01/server.102/b14200/functions110.htm):

> PERCENTILE_CONT is an inverse distribution function that assumes a continuous distribution model. It takes a percentile value and a sort specification, and returns an interpolated value that would fall into that percentile value with respect to the sort specification. Nulls are ignored in the calculation.

In PostGres9.4 and up we have
[ordered set aggregates](https://www.depesz.com/2014/01/11/waiting-for-9-4-support-ordered-set-within-group-aggregates/)
which are needed to find those percentiles. Let's try it on our tags:

    SELECT PERCENTILE_CONT(array[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]) WITHIN GROUP(ORDER by score) FROM     tags;
    
       percentile_cont
    ---------------------
     {0,0,0,0,0,0,1,1,2}

This shows that the majority of our rows have a null score.
From here we can say these scores are innapropriate for sorting.


## "Look at your data" also means "start by looking at samples"

You likely already heard this advice, but it's worth repeating: **look at your data**.
However that doesn't mean you should spend hours on tracing fancy graphs!
Sampling a few times is enough to catch a wandering elephant in your corridor.
With Postgres it's _very_ easy:

    SELECT * FROM tags ORDER BY random() LIMIT 10;

In our example this short line would have been enough to
understand that the majority of our rows have a null score.

So here's the 2 minutes-check-list you should always start with in this task:

1. look at a few dozens samples
2. compute basic statistics
3. compute deciles

Then you will likely be able to decide if your scoring function fits your needs or not.
