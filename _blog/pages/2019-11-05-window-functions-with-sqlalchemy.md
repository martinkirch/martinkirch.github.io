title: Fetch the "first in a group by"
briefing: Or, using window functions with SQLAlchemy
date_time: 2019-11-05 20:00
slug: window-functions-with-sqlalchemy
tags: data, postgres
type: post


# The problem

Let's say I have `Document`s in PostgreSQL, that among other great content
include a `folder_id` and a `date`.

**How do I fetch the most recent document in each folder ?**

In SQL, this is possible by turning by folders into windows (also called partitions).
The big difference with `GROUP BY` is that the engine keeps (and returns, by default) all concerned rows.
It just changes their order to make up each group and maybe order within each group.

Some functions are designed to work on these windows: it's a powerful tool
better explained and illustrated by the 
[Postgres Tutoriql](http://www.postgresqltutorial.com/postgresql-window-function/).
In the following I'll assume you know what they do.

# Explaining this to SQLAlchemy

`GROUP BY` can be used with a `HAVING` clause in order to filter,
but there's not equivalent for window functions.
In other words, we'll have create our windows in a sub-query that also returns
each document's rank in the group, then filter to only keep those ranking first.

This is where it gets complicated with SQLAlchemy: in the top query we
just want to fetch `Document`s, but we need a way to explain to describe that
the complete `Document` comes from the sub-query.
My first and intuitive attempt created a self-join on my documents table.
Instead, we have to use advanced SQLAlchemy aliases.

We firstly have to detail the window function and its grouping/ordering :

    rownb = sa.func.row_number().over(order_by=Document.date.desc(), partition_by=Document.folder_id)
    rownb = rownb.label('rownb')





