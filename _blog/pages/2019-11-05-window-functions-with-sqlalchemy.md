title: Fetch the "first in a group by"
briefing: Or, using window functions with SQLAlchemy
date_time: 2019-11-05 20:00
slug: window-functions-with-sqlalchemy
tags: data, postgres
type: post


# The problem

Let's say I have `Document`s in PostgreSQL, that among other great content
include a `folder_id` and a `date`.

**How do I fetch (only) the most recent document from each folder ?**

In SQL, this is possible by turning folders into windows (also called partitions).
The big difference with `GROUP BY` is that the engine keeps (and returns, by default) all concerned rows.
It just changes their order, to distinguish groups and maybe order within each group.

Some functions are designed to work on these windows: it's a powerful tool
better explained and illustrated by the 
[Postgres Tutoriql](http://www.postgresqltutorial.com/postgresql-window-function/).
In the following I'll assume you know what they do.

# Explaining this to SQLAlchemy

To filter rows in a group, `GROUP BY` can be used with a `HAVING` clause.
But there's not equivalent for window functions.
With window functions, we can only filter results from a sub-query.
So this sub-query will compute partitions, and return
each document's rank in the partition ;
then top query will only have to keep rows ranking first.

This is where it gets complicated with SQLAlchemy: in the top query we
just want to fetch `Document`s, but we need a way to describe that
the complete `Document` comes from the sub-query.
My first and intuitive attempt created a self-join on my documents table.
Instead, we have to use SQLAlchemy aliases.

We firstly have to detail the window function and its grouping/ordering ;
this function is added to the sub-query's selected columns,
and made available by two SQLQlchemy tricks:

```python
rownb = sa.func.row_number().over(order_by=Document.date.desc(), partition_by=Document.folder_id)
rownb = rownb.label('rownb')

subq = session.query(Document, rownb) # add interesting filters here

# we need these two lines to match Document columns in subq, and to filter by rownb
subq = subq.subquery(name="subq", with_labels=True)
q = session.query(sa.orm.aliased(Document, alias=subq)).filter(subq.c.rownb == 1)
```

Hope this helps !
