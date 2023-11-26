---
layout: post
title:  "Partial Application in Python: A look under the hood of popular python repositories on GitHub"
date:   2023-10-12 21:31:54 +1000
thumbnail: https://cdn-images-1.medium.com/max/2048/1*wmihy9TV2z6x238jY4C6Hw.png
tags: [functional programming, Python]
categories: fop
---

# What is Partial Application?
Partial application or partial function application is a very powerful technique in [functional programming](https://en.wikipedia.org/wiki/Functional_programming). Using partial application we can fix some or all of arguments of a function with any values and as result we get another function with less or no arguments.
In functional first languages, partial application enables function composition and piping. [Haskell](https://wiki.haskell.org/Partial_application) or [F#](https://fsharpforfunandprofit.com/posts/partial-application/) are well-known examples.
In Python partial application is supported by the language in [``functools``](https://docs.python.org/3/library/functools.html#functools.partial) library. A classic example of this is making ``power2`` function which calculates only ``x^2`` from a function called ``powern`` which calculates ``x^n``.

```python
def powern(x,n):
    return x**n
power2 = partial(powern,n=2)

print(powern(3,2)) // Prints 9
print(power2(3))   // Also prints 9

```
In the above example we converted ``powern`` function with 2 arguments to ``power2`` function with only one argument. The line which did this conversion for us was ``power2 = partial(powern,n=2)``. If you look closer you will notice ``partial`` itself is a function which is called by ``powern`` as it's first argument and `2` as the second. The ``partial`` function under the hood freezes argument ``n`` with number ``2`` and gives us another function which we name it ``power2``.
If it was F# we could we could compose `power2` with other functions and create new functions. The following is to calculate sum of squares of first n natural numbers using ``power2`` function in F#.

```f#
let sumOfSquares n =
    seq {1 .. n}
    |> Seq.map power2
    |> Seq.sum
```
But is it the same for Python? How Python ecosystem usually apply this technique? 

# Why
1) How others use that?
2) Sometimes we think a pattern is useful for something but in practice it is different
3) Learning from most used battle tested code

# Searching most popular Python repositories on Github
For this article I did a search on 100+ python repositories on Github which had more than 100 number of stars and at least used ``partial`` keyword once over the whole repository. Here is the [source code]() used for this article.
Then I short listed well-known repositories e.g. pip, Panda, Conda, etc. In some repositories partial application was used multiple times but I only picked one use case. Additionally, in many repos the usage of the technique was not very interesting or it was complicated and not suitable to be discussed here. I also, prioritised the samples which partial application was pivotal for the core problem that the repository was solving.

## Dry run of Conda commands
[Conda](https://github.com/conda/conda/tree/main) is a popular package manager. With Conda you can create multiple independent python environments and switch between them when needed. There is also a dry run option which you can use to see how each of Conda's commands would impact the current environment setup. The interesting command we studying here is ``Conda rename``. [This command](https://docs.conda.io/projects/conda/en/latest/commands/rename.html) would change the name of an environment. See below a sample usage of this command,
```sh
$ Conda rename -n oldname newname
```
The command also has a few options, one of them is dry run ``-d``, which prints a preview of what would the command do without actually applying the changes. Let see an example,
```sh
$ conda rename -n oldname newname -d

Dry run action: clone /usr/local/Caskroom/miniconda/base/envs/oldname,/usr/local/Caskroom/miniconda/base/envs/newname
Dry run action: rm_rf /usr/local/Caskroom/miniconda/base/envs/oldname

```
As you see above dry run shows two actions:

1) Cloning the current environment to a new path with the new name
2) Removing current environment 

Now let's have a look at Conda's source code to find out how it is implemented. Rename command is implemented [here](https://github.com/conda/conda/blob/e69b2353c2f14fbfc9fd3aa448ebc991b28ca136/conda/cli/main_rename.py#L127).
The following is a code extract from ```main_rename.py```.
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
#..........................
```
In the code above the function ```clone_and_remove``` creates a tuple of the actions wich should happen as part of the rename command. You can see two ```partial``` function calls to create two functions for first cloning the environment and second removing the old one. ```clone``` and ```rm_rf``` are the two functions which execute the actual actions. The next lines are where the magic happens. The code checks for ```args.dry_run``` and only prints the function names and their arguments otherwise calls each function.

## Consistent bidirectional mapping in bidict
[Bidict](https://github.com/jab/bidict/) is a Python library designed for bidirectional mapping between keys and values. 
With bidicts, two sets (dicts) are employed to manage relationships in both directions: from keys to values and vice versa. This bidirectional capability is invaluable in scenarios where maintaining consistency between the two sets is crucial.
An intriguing feature of Bidict is its ability to handle update failures gracefully, following a [fails clean](https://bidict.readthedocs.io/en/main/basic-usage.html#updates-fail-clean) approach. In the event of an error during an update operation, Bidict automatically rolls back the changes, preventing partial updates and maintaining a consistent state. This robust behavior enhances data integrity and ensures that the bidict remains in a valid state, even in the face of failures.
The following is an example of how the library would gracefully handle a key duplication.

```python
b = bidict({1: 'one', 2: 'two'})
b.putall([(3, 'three'), (1, 'uno')])

# (1, 'uno') was the problem...
b  # ...but (3, 'three') was not added either:
bidict({1: 'one', 2: 'two'})
```
Now lets look under the hood of the library. ```_perp_write``` is the [function]([https://github.com/jab/bidict/blob/7ed2ce59738a1127375ca25a2f8b2c7437514478/bidict/_base.py#L389]) which prepare the operations needed for write operation upfront.
```python
 def _prep_write(self, newkey: KT, newval: VT, oldkey: OKT[KT], oldval: OVT[VT], save_unwrite: bool) -> PreparedWrite:
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
Before each write operation, Bidict prepares operations for both writing and unwriting, see ```write``` and ```unwrite``` lists in the code above.
These operations serve as a set of instructions to update both sets of the bidict. In case of a failure during the update, Bidict seamlessly rolls back these operations, preventing any partial or inconsistent changes by running all of operations in ```unwrite``` list.
All of the operations in those two lists are pre-setup using partial application. The functions which do the actual writing are ```fwdm_set``` for updating the forward dictionary and ```invm_set``` for updating the inverse one.

## Pre-configuration of options for pip
[Pip](https://pip.pypa.io/en/stable/) is a widely-used package installer for Python, facilitating the management of Python packages. Users commonly interact with Pip to install, upgrade, or uninstall packages in their Python environments.
When using the command `pip install -h`, the `-h` option is utilized to display the help information for the `pip install` command. In the context of Pip, each option is represented as a class, providing a structured and modular approach to command-line options.
Pip initializes its options through the definition of classes, as evident in its source code [here](https://github.com/pypa/pip/blob/2a0acb595c4b6394f1f3a4e7ef034ac2e3e8c17e/src/pip/_internal/cli/cmdoptions.py#L121). These options are parsed and processed during various commands.
It's important to note that while the classes define options, they are not instantiated globally when common options are being defined. Instead, options can be used and shared among commands, allowing for flexibility and code reuse. However, to ensure isolation between commands, options are not instantiated globally.
Here is an example code extract from Pip's source code illustrating the definition of two options - `help_` and `debug_mode`:

```python
#................................

help_: Callable[..., Option] = partial(
    Option,
    "-h",
    "--help",
    dest="help",
    action="help",
    help="Show help.",
)

debug_mode: Callable[..., Option] = partial(
    Option,
    "--debug",
    dest="debug_mode",
    action="store_true",
    default=False,
    help=(
        "Let unhandled exceptions propagate outside the main subroutine, "
        "instead of logging them to stderr."
    ),
)

#................................
```

Notice how partial application helps with defining these options and freezing the parameters.

## Overriding default sql insert in Panda Dataframes
[Pandas](https://pandas.pydata.org/) is a widely-used data manipulation library in Python, offering powerful data structures like DataFrames. DataFrames provide a tabular structure for working with data, offering flexibility and ease of use. One of the notable functionalities in Pandas is the `to_sql` method, allowing users to insert DataFrame data into a SQL database.

The `to_sql` method can be found in the Pandas documentation [here](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_sql.html). An example use case involves inserting a DataFrame into a table, with the ability to handle conflicts by ignoring the insert, as demonstrated in the following code:

```python
def insert_on_conflict_nothing(table, conn, keys, data_iter):
    # "a" is the primary key in "conflict_table"
    data = [dict(zip(keys, row)) for row in data_iter]
    stmt = insert(table.table).values(data).on_conflict_do_nothing(index_elements=["a"])
    result = conn.execute(stmt)
    return result.rowcount

df_conflict.to_sql(name="conflict_table", con=conn, if_exists="append", method=insert_on_conflict_nothing)
```

In this example, the ```insert_on_conflict_nothing``` function is passed as the method argument, allowing users to customize the behavior when conflicts occur during the insert.

The implementation of the to_sql method is provided [here](https://github.com/pandas-dev/pandas/blob/2d2d67db48413fde356bce5c8d376d5b9dd5d0c2/pandas/io/sql.py#L1037). Users can override the way the insert operation happens by passing a custom function to the method parameter.
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
The ```exec_insert``` function plays a crucial role in performing the insert operation and can be assigned to a different function depending on the method argument. If the method has a value, it is set by the function passed as this argument. Partial application is used to make the insert function passed as an argument appear like a method on the same class, providing access to "self".

# Can be used for function decorators

[JAX](https://jax.readthedocs.io/) is a library commonly used for just-in-time (JIT) compilation in computations, particularly in performance-critical applications like deep learning. The `jax.jit` function is a key feature for optimizing computations by compiling and optimizing functions on-the-fly.

The [official documentation for `jax.jit`](https://jax.readthedocs.io/en/latest/_autosummary/jax.jit.html#jax.jit) provides comprehensive information on how to utilize JIT compilation effectively.

JIT can be seamlessly applied as a function decorator, making it convenient to speed up specific computations. A common practice is to use partial application when passing arguments to the JIT-compiled function. This flexibility allows users to customize the behavior of the compiled function by supplying specific arguments.

The `static_argnames` parameter in JIT is crucial for controlling when to recompile a function. By specifying which arguments are considered static, users can manage the trade-off between compilation overhead and performance gains. An example of using `static_argnames` can be found in the source code [here](https://github.com/google-research/google-research/blob/70796b286879cf0fe27c66aa79c0a6413ab70a62/pvn/indicator_functions.py#L97).

Here is an example of how JIT is used as a function decorator with partial application for a math computation function:

```python
@functools.partial(
    jax.jit, static_argnames=('mersenne_prime_exponent', 'num_bins')
)
def multiply_shift_hash_function(
    x,
    params,
    *,
    mersenne_prime_exponent,
    num_bins,
):  # pyformat: disable
  """Multiply shift hash function."""
 #...............................
```
In this example, the ``multiply_shift_hash_function`` is decorated with ``jax.jit`` using partial application, specifying the ``static_argnames`` as arguments for more efficient compilation and execution.

# Other findings which wasn't mentioned here
1) Ternsorflow
2) pytorch,https://github.com/pytorch/pytorch/blob/e66ec5843f6cc203de5570059794a3ae14dab4ae/torch/profiler/_utils.py#L24
3) saleor,[https://github.com/saleor/saleor/blob/d69bb446eff47a767903bdbe840b7db25532b3b0/saleor/discount/models.py#L133] 
4) Home IOT

# Performance drawbacks
1) It is slower
```python
import timeit

setting = """
import functools

def f(a,b,c):
    pass

g = functools.partial(f, 4)
h = functools.partial(f, 4, 5)
i = functools.partial(f, 4, 5, 3)
"""

print(timeit.timeit('f(4, 5, 3)', setup = setting, number=100000)*1000)
print(timeit.timeit('g(5, 3)',    setup = setting, number=100000)*1000)
print(timeit.timeit('h(3)',       setup = setting, number=100000)*1000)
print(timeit.timeit('i()',        setup = setting, number=100000)*1000)
```
```
6.880872999317944
9.710253012599424
10.193951980909333
9.41502299974672
```
2) here to show why is slower using this benchmark
3) Why it is slower?
4) Is there any usage when you prefer no to use it?
5) Why the result is different when using pypy? why calling h is quicker than other partially applied functions?

```
1.1300640180706978
15.009083988843486
4.196833004243672
13.206779985921457
```

# How they work under the hood
1) How it works?
2) How you can't call it with more args than it freezes
3) is it different in CPython and other Python implementations?
4) what is Modules/_functoolsmodule.c vs Lib/functools.py which one is the implementation? 
   ```python
   class partial:
    """New function with partial application of the given arguments
    and keywords.
    """

    __slots__ = "func", "args", "keywords", "__dict__", "__weakref__"

    def __new__(cls, func, /, *args, **keywords):
        if not callable(func):
            raise TypeError("the first argument must be callable")

        if hasattr(func, "func"):
            args = func.args + args
            keywords = {**func.keywords, **keywords}
            func = func.func

        self = super(partial, cls).__new__(cls)

        self.func = func
        self.args = args
        self.keywords = keywords
        return self

    def __call__(self, /, *args, **keywords):
        keywords = {**self.keywords, **keywords}
        return self.func(*self.args, *args, **keywords)

    @recursive_repr()
    def __repr__(self):
        qualname = type(self).__qualname__
        args = [repr(self.func)]
        args.extend(repr(x) for x in self.args)
        args.extend(f"{k}={v!r}" for (k, v) in self.keywords.items())
        if type(self).__module__ == "functools":
            return f"functools.{qualname}({', '.join(args)})"
        return f"{qualname}({', '.join(args)})"

    def __reduce__(self):
        return type(self), (self.func,), (self.func, self.args,
               self.keywords or None, self.__dict__ or None)

    def __setstate__(self, state):
        if not isinstance(state, tuple):
            raise TypeError("argument to __setstate__ must be a tuple")
        if len(state) != 4:
            raise TypeError(f"expected 4 items in state, got {len(state)}")
        func, args, kwds, namespace = state
        if (not callable(func) or not isinstance(args, tuple) or
           (kwds is not None and not isinstance(kwds, dict)) or
           (namespace is not None and not isinstance(namespace, dict))):
            raise TypeError("invalid partial state")

        args = tuple(args) # just in case it's a subclass
        if kwds is None:
            kwds = {}
        elif type(kwds) is not dict: # XXX does it need to be *exactly* dict?
            kwds = dict(kwds)
        if namespace is None:
            namespace = {}

        self.__dict__ = namespace
        self.func = func
        self.args = args
        self.keywords = kwds
   ```

# Other ways which might give you the same result
1) Using local functions
2) using lambdas
3) What is the difference? 
4) You can use copy functions [https://stackoverflow.com/questions/17388438/python-functools-partial-efficiency#:~:text=The%20code%20with%20partial%20takes,speed%20of%20a%20builtin%20function]
5) Why would someone want to deep copy a function
```python
import timeit
import types


# http://stackoverflow.com/questions/6527633/how-can-i-make-a-deepcopy-of-a-function-in-python
def copy_func(f, name=None):
    return types.FunctionType(f.func_code, f.func_globals, name or f.func_name,
        f.func_defaults, f.func_closure)


def f(a, b, c):
    return a + b + c


i = copy_func(f, 'i')
i.func_defaults = (4, 5, 3)


print timeit.timeit('f(4,5,3)', setup = 'from __main__ import f', number=100000)
print timeit.timeit('i()', setup = 'from __main__ import i', number=100000)
```




### ----------------------------------------------------

Another good example in pytorch 
https://github.com/pytorch/pytorch/blob/e66ec5843f6cc203de5570059794a3ae14dab4ae/torch/profiler/_utils.py#L24
creating two bfs and dfs using a traverse function

```python

traverse_dfs = functools.partial(_traverse, next_fn=lambda x: x.pop(), reverse=True)
traverse_bfs = functools.partial(
    _traverse, next_fn=lambda x: x.popleft(), reverse=False
)

```

```python

def _traverse(tree, next_fn, children_fn=lambda x: x.children, reverse: bool = False):
    order = reversed if reverse else lambda x: x
    remaining = deque(order(tree))
    while remaining:
        curr_event = next_fn(remaining)
        yield curr_event
        for child_event in order(children_fn(curr_event)):
            remaining.append(child_event)
```

## Some sort of factory

# Factory for discount calculations in retail applications 
()[https://github.com/saleor/saleor/blob/d69bb446eff47a767903bdbe840b7db25532b3b0/saleor/discount/models.py#L133]
1) creates a discount function
2) models discount with a function 
3) two different discounts created using partial
   1) Fixed
   2) Percentage
4) 

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

# creates a factory function to read from sensor

1) IOT, home assistant, real time usage 
2) Creates multiple versions of factory to read from DSMR sensors for meters 
```python
protocol = entry.data.get(CONF_PROTOCOL, DSMR_PROTOCOL)
    if CONF_HOST in entry.data:
        if protocol == DSMR_PROTOCOL:
            create_reader = create_tcp_dsmr_reader
        else:
            create_reader = create_rfxtrx_tcp_dsmr_reader
        reader_factory = partial(
            create_reader,
            entry.data[CONF_HOST],
            entry.data[CONF_PORT],
            dsmr_version,
            update_entities_telegram,
            loop=hass.loop,
            keep_alive_interval=60,
        )
    else:
        if protocol == DSMR_PROTOCOL:
            create_reader = create_dsmr_reader
        else:
            create_reader = create_rfxtrx_dsmr_reader
        reader_factory = partial(
            create_reader,
            entry.data[CONF_PORT],
            dsmr_version,
            update_entities_telegram,
            loop=hass.loop,
        )

    async def connect_and_reconnect() -> None:
        """Connect to DSMR and keep reconnecting until Home Assistant stops."""
        stop_listener = None
        transport = None
        protocol = None

        while hass.state == CoreState.not_running or hass.is_running:
            # Start DSMR asyncio.Protocol reader

            # Reflect connected state in devices state by setting an
            # empty telegram resulting in `unknown` states
            update_entities_telegram({})

            try:
                transport, protocol = await hass.loop.create_task(reader_factory())

                if transport:
                    # Register listener to close transport on HA shutdown
                    @callback
                    def close_transport(_event: Event) -> None:
                        """Close the transport on HA shutdown."""
                        if not transport:  # noqa: B023
                            return
                        transport.close()  # noqa: B023

                    stop_listener = hass.bus.async_listen_once(
                        EVENT_HOMEASSISTANT_STOP, close_transport
                    )

```
