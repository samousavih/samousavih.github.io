---
layout: post
title:  "functional Python: Partial Application"
date:   2023-10-12 21:31:54 +1000
thumbnail: https://cdn-images-1.medium.com/max/2048/1*wmihy9TV2z6x238jY4C6Hw.png
tags: [functional programming, Python]
categories: fop
---

# What is Partial Application?
Partial application or partial function application is a very powerful technique in [functional programming](https://en.wikipedia.org/wiki/Functional_programming). Using partial application we can fix some or all of arguments of a function with any values and as result we get another function with less or no arguments. A classic example of this is making ``power2`` function which calculates only ``x^2`` from a function called ``powern`` which calculates ``x^n``.

```python
def powern(x,n):
    return x**n
power2 = partial(powern,n=2)

print(powern(3,2)) // Prints 9
print(power2(3))   // Also prints 9

```
In the above example we converted ``powern`` function with 2 arguments to ``power2`` function with only one argument. The line which did this conversion for us was ``power2 = partial(powern,n=2)``. If you look closer you will notice ``partial`` itself is a function which is called by ``powern`` as it's first argument and `2` as the second. The ``partial`` function under the hood freezes argument ``n`` with number ``2`` and gives us another function which we name it ``power2``.


# Some of interesting ways partial application is used by searching Github

- Real world examples
- Reading code
- Source code
  
## Passing functions and baking in arguments and dependencies

an example of returning a function [https://github.com/saleor/saleor/blob/d69bb446eff47a767903bdbe840b7db25532b3b0/saleor/discount/models.py#L133]
1) models discount with a function 
2) two different discounts created using partial
   1) Fixed
   2) Percentage
3) 

```python
 def get_discount(self, channel: Channel):
        # .........................
        if self.discount_value_type == DiscountValueType.FIXED:
            discount_amount = Money(
                voucher_channel_listing.discount_value, voucher_channel_listing.currency
            )
            return partial(fixed_discount, discount=discount_amount)
        if self.discount_value_type == DiscountValueType.PERCENTAGE:
            return partial(
                percentage_discount,
                percentage=voucher_channel_listing.discount_value,
                rounding=ROUND_HALF_UP,
            )
```
```python
def get_discount_amount_for(self, price: Money, channel: Channel):
        discount = self.get_discount(channel)
        after_discount = discount(price)
        if after_discount.amount < 0:
            return price
        return price - after_discount

```


### Separating action definition from execution
In Conda [https://github.com/conda/conda/blob/e69b2353c2f14fbfc9fd3aa448ebc991b28ca136/conda/cli/main_rename.py#L127]
 

1) it is [Conda rename](https://docs.conda.io/projects/conda/en/latest/commands/rename.html) which renames an environment
2) Defines actions without running them
   1) clone current environment
   2) remove current environment 
3) make a list 
4) does dry run by printing the name and arguments of each action or actually running the actions

```python
def execute(args: Namespace, parser: ArgumentParser) -> int:
    """Executes the command for renaming an existing environment."""
    from ..base.constants import DRY_RUN_PREFIX
    from ..base.context import context
    from ..cli import install
    from ..gateways.disk.delete import rm_rf
    from ..gateways.disk.update import rename_context

    source = validate_src()
    destination = validate_destination(args.destination, force=args.force)

    def clone_and_remove() -> None:
        actions: tuple[partial, ...] = (
            partial(
                install.clone,
                source,
                destination,
                quiet=context.quiet,
                json=context.json,
            ),
            partial(rm_rf, source),
        )

        # We now either run collected actions or print dry run statement
        for func in actions:
            if args.dry_run:
                print(f"{DRY_RUN_PREFIX} {func.func.__name__} {','.join(func.args)}")
            else:
                func()

    if args.force:
        with rename_context(destination, dry_run=args.dry_run):
            clone_and_remove()
    else:
        clone_and_remove()
    return 0
```

Another example is bidict [https://github.com/jab/bidict/blob/7ed2ce59738a1127375ca25a2f8b2c7437514478/bidict/_base.py#L389]
1) It has two sets(dicts) for key -> value and vice versa and always keeps them consistent 
2) before each write it prepares the operations for write and unwrite
3) Then runs those operations

```python
 def _prep_write(self, newkey: KT, newval: VT, oldkey: OKT[KT], oldval: OVT[VT], save_unwrite: bool) -> PreparedWrite:
        """Given (newkey, newval) to insert, return the list of operations necessary to perform the write.

        *oldkey* and *oldval* are as returned by :meth:`_dedup`.

        If *save_unwrite* is true, also return the list of inverse operations necessary to undo the write.
        This design allows :meth:`_update` to roll back a partially applied update that fails part-way through
        when necessary. This design also allows subclasses that require additional operations to complete
        a write to easily extend this implementation. For example, :class:`bidict.OrderedBidictBase` calls this
        inherited implementation, and then extends the list of ops returned with additional operations
        needed to keep its internal linked list nodes consistent with its items' order as changes are made.
        """
        fwdm, invm = self._fwdm, self._invm
        fwdm_set, invm_set = fwdm.__setitem__, invm.__setitem__
        fwdm_del, invm_del = fwdm.__delitem__, invm.__delitem__
        write: list[t.Callable[[], None]] = [
            partial(fwdm_set, newkey, newval),
            partial(invm_set, newval, newkey),
        ]
        write_append = write.append
        unwrite: list[t.Callable[[], None]] = []
        if oldval is MISSING and oldkey is MISSING:  # no key or value duplication
            # {0: 1, 2: 3} + (4, 5) => {0: 1, 2: 3, 4: 5}
            if save_unwrite:
                unwrite = [
                    partial(fwdm_del, newkey),
                    partial(invm_del, newval),
                ]
        elif oldval is not MISSING and oldkey is not MISSING:  # key and value duplication across two different items
            # {0: 1, 2: 3} + (0, 3) => {0: 3}
            write_append(partial(fwdm_del, oldkey))
            write_append(partial(invm_del, oldval))
            if save_unwrite:
                unwrite = [
                    partial(fwdm_set, newkey, oldval),
                    partial(invm_set, oldval, newkey),
                    partial(fwdm_set, oldkey, newval),
                    partial(invm_set, newval, oldkey),
                ]
        elif oldval is not MISSING:  # just key duplication
            # {0: 1, 2: 3} + (2, 4) => {0: 1, 2: 4}
            write_append(partial(invm_del, oldval))
            if save_unwrite:
                unwrite = [
                    partial(fwdm_set, newkey, oldval),
                    partial(invm_set, oldval, newkey),
                    partial(invm_del, newval),
                ]
        else:
            assert oldkey is not MISSING  # just value duplication
            # {0: 1, 2: 3} + (4, 3) => {0: 1, 4: 3}
            write_append(partial(fwdm_del, oldkey))
            if save_unwrite:
                unwrite = [
                    partial(fwdm_set, oldkey, newval),
                    partial(invm_set, newval, oldkey),
                    partial(fwdm_del, newkey),
                ]
        return write, unwrite
```


### Overriding the default behavior of a method

Dataframe has a `to_sql` (https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_sql.html)

the following code does inserts a Dataframe into a table but in the case of a conflict ignores the insert, the method argument overwrites the default behavior of insert

```python
from sqlalchemy.dialects.postgresql import insert
def insert_on_conflict_nothing(table, conn, keys, data_iter):
    # "a" is the primary key in "conflict_table"
    data = [dict(zip(keys, row)) for row in data_iter]
    stmt = insert(table.table).values(data).on_conflict_do_nothing(index_elements=["a"])
    result = conn.execute(stmt)
    return result.rowcount
df_conflict.to_sql(name="conflict_table", con=conn, if_exists="append", method=insert_on_conflict_nothing)  
```

example here 
https://github.com/pandas-dev/pandas/blob/2d2d67db48413fde356bce5c8d376d5b9dd5d0c2/pandas/io/sql.py#L1037

 we can override the way insert happens by passing a function

 ```python
 def insert(
        self,
        chunksize: int | None = None,
        method: Literal["multi"] | Callable | None = None,
    ) -> int | None:
        # set insert method
        if method is None:
            exec_insert = self._execute_insert
        elif method == "multi":
            exec_insert = self._execute_insert_multi
        elif callable(method):
            exec_insert = partial(method, self)
        else:
            raise ValueError(f"Invalid parameter `method`: {method}")

        keys, data_list = self.insert_data()

        nrows = len(self.frame)

        if nrows == 0:
            return 0

        if chunksize is None:
            chunksize = nrows
        elif chunksize == 0:
            raise ValueError("chunksize argument should be non-zero")

        chunks = (nrows // chunksize) + 1
        total_inserted = None
        with self.pd_sql.run_transaction() as conn:
            for i in range(chunks):
                start_i = i * chunksize
                end_i = min((i + 1) * chunksize, nrows)
                if start_i >= end_i:
                    break

                chunk_iter = zip(*(arr[start_i:end_i] for arr in data_list))
                num_inserted = exec_insert(conn, keys, chunk_iter)
                # GH 46891
                if num_inserted is not None:
                    if total_inserted is None:
                        total_inserted = num_inserted
                    else:
                        total_inserted += num_inserted
        return total_inserted
 ```

``exec_insert`` can be assigned to a different functon depending on the argument of insert in the case of argument ``method`` has a value it would be set by the function passed as this argument. and the ``exec_insert`` would be called to perform the insert operation.
It could have been only ``exec_insert = method`` instead of ``exec_insert = partial(method, self)``?##Should Ask Someone##

### Better readability by pre-configurations 
pre-configuring multiple options 
https://github.com/pypa/pip/blob/main/src/pip/_internal/cli/cmdoptions.py

predefined commands/operations

https://github.dev.xero.com/Xero/dt-slim-contacts/blob/d1443de0d445759b0ba9753eaadf5b4229cacb09/src/tasks/data/make.py

Another good example in pytorch 
https://github.com/pytorch/pytorch/blob/e66ec5843f6cc203de5570059794a3ae14dab4ae/torch/profiler/_utils.py#L24
creating two bfs and dfs using a traverse function


### Fitting functions 
https://datascience.stackexchange.com/questions/11356/merging-multiple-data-frames-row-wise-in-pyspark
joining dataframes 

```Python
master_join = partial(pyspark.sql.DataFrame.join, on="master", how="outer")
all_warnings = reduce(master_join, warnings)
```
# Can be used as attributes
https://github.com/google-research/google-research/blob/70796b286879cf0fe27c66aa79c0a6413ab70a62/pvn/indicator_functions.py#L97

# avoid repetition of an argument 
https://github.com/django/django/blob/656192c2c96bb955a399d92f381e38fe2254fe17/django/db/backends/sqlite3/_functions.py#L40

# creates a factory function to read from sensor
https://github.com/home-assistant/core/blob/ab6b3d56682855e1eb7a92ba4baa6905cd1e01e5/homeassistant/components/dsmr/sensor.py#L505

# used in EvoJAX for JIT compiler? 
https://github.com/google/evojax/blob/67c90e1ad3655097ff7b56f4975d43ff30d8e49c/evojax/obs_norm.py#L115

# Performance drawbacks

# How they work under the hood

# Other ways which might give you the same result


# Link to the repo used to find samples


# -----------------------------------

```python
def dataBaseMigration(firstdb_username,firstdb_pass,firstdb_host_url ,seconddb_username,secondb_pass,secondb_host_url):
    firstConnection = connect(firstdb_host_url,firstdb_username,firstdb_pass)
    secondConnection = connect(seconddb_host_url,seconddb_username,seconddb_pass)
    data = firstConnection.read()
    data1 = convert(data)
    secondConnection.werite(data1)


def main():
#firstdb_username,
#firstdb_pass,firstdb_host_url ,seconddb_username,secondb_pass,secondb_host_url
dataBaseMigration(adasdas)

```

```python
def dataBaseMigration(connectToFirstDb,connectToSecondDb):
    firstConnection = connectToFirstDb()
    secondConnection = connectToSecondDb()
    data = firstConnection.read()
    data1 = convert(data)
    secondConnection.werite(data1)


def main():
#firstdb_username,
#firstdb_pass,firstdb_host_url ,seconddb_username,secondb_pass,secondb_host_url
connectToFirstDb = parial(connect,firstdb_host_url,firstdb_username,firstdb_pass)
connectToSecondDb = parial(connect,firstdb_host_url,firstdb_username,firstdb_pass)
dataBaseMigration(connectToFirstDb,connectToSecondDb)

```
### baking in dependencies

``doSomething(input, logger)`` the following is the code for this function.

```python
def doSomething(input, logger):
    ActuallyDoTheThings(input)
    logger("the thing is done")
```
The above function after it's core operation also logs a message so we can track it worked. Logging happens using another function called ``logger`` which we are passing as an argument. Let's have a look at the logger function,

```python
def logger(message):
    print(message)
```
Now we can fix the logger argument in ``doSomething(input, logger)`` then we have a function called ``doSomethingWithLogger(input)``. Imagine we do this

```python
doSomethingWithLogger = partial(doSomething, logger:logger)
```
And you can guess if we call ``doSomethingWithLogger`` and provide it's only argument it would be the same as calling ``doSomething`` and provide both input and logger arguments.

```Python
doSomething(1,logger)
doSomethingWithLogger(1)
```
