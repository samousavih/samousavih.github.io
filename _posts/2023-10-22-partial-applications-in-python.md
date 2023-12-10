---
layout: post
title:  "Partial Application in Python: A look under the hood of popular python repositories on GitHub"
date:   2023-10-12 21:31:54 +1000
thumbnail: https://cdn-images-1.medium.com/max/2048/1*wmihy9TV2z6x238jY4C6Hw.png
tags: [functional programming, Python]
categories: fop
---

# Abstract
Python community applies partial function application across many popular code repositories. Among them are Panda, Conda and pip 
which this functional technique helps with exciting designs. Considering Python is not a functional first language, the usage of partial application, is different to what is common in functional first languages, e.g. Haskel or F#.

# Motivation
I have recently needed to write a utility application in Python which dumps data from multiple http services into a database. In the code I applied a famous functional pattern called partial function application in a certain way. I have learned the pattern by studying [F#](https://fsharpforfunandprofit.com/posts/partial-application/) and knew one or two things about it's application. So decided to utilise my learnings and apply that to the code specially because Python already has an out the box library for functional programming including partial application called [``functools``](https://docs.python.org/3/library/functools.html#functools.partial). Afterwards, this thought came to me that how others would do this? Would someone with more experience in Python do what I did? How partial application is used across python community and in well-known, most used repositories in Github? So I decided to explore Github and find use cases of the technique and learn from it.

# What is Partial Function Application?
Partial application or partial function application is a powerful technique in [functional programming](https://en.wikipedia.org/wiki/Functional_programming). Using partial application we can fix some or all of arguments of a function with values and as result have another function with less or no arguments.
In functional first languages, partial application enables function composition and piping. [Haskell](https://wiki.haskell.org/Partial_application) or [F#](https://fsharpforfunandprofit.com/posts/partial-application/) are well-known examples.
In Python, partial application is supported by out of the box [``functools``](https://docs.python.org/3/library/functools.html#functools.partial) library.
A classic example of this is making ``power2`` function from ``powern`` function, buy fixing ``n`` with 2.

```python
def powern(x,n):
    return x**n
power2 = partial(powern,n=2)

print(powern(3,2)) // Prints 9
print(power2(3))   // Also prints 9

```
In the above example we transformed ``powern`` function with 2 arguments to ``power2`` function with only one argument. The trasformation happnes by ``power2 = partial(powern,n=2)``. If you look closer you will notice ``partial`` itself is a function which is called by ``powern`` as it's first argument and `2` as the second. The ``partial`` function under the hood freezes argument ``n`` with number ``2`` and gives us another function which we name it ``power2``.
If it was F# we could compose `power2` with other functions and create a new function. The following is to calculate sum of squares of first n natural numbers using ``power2`` in F#.

```f#
let sumOfSquares n =
    seq {1 .. n}
    |> Seq.map power2
    |> Seq.sum
```
Another variation of this example is to freeze dependencies. Imagine ``powern`` function had another argument to log for observability, ``powern(x,n,logger)``.

```python
def powern(x,n,logger):
    logger("calculating {x}^{n}")
    return x**n

power2_with_logger = partial(powern,n=2,logger=console_logger)

print(power2_with_logger(3)) // calculating 3^2 9

```
And again if it was F# we could easily compose with other functions, as ```power2_with_logger``` has now only one argument.
```f#
let sumOfSquares n =
    seq {1 .. n}
    |> Seq.map power2_with_logger
    |> Seq.sum
```

Of course I am not suggesting that functions defined in python can be used in F# but only wanted to show the common usages of partial function application in functional languages without needing to know about their syntax much.


# How I used Partial Function Application
The code I wrote which lead to this article was roughly similar to the following code extract. I say roughly because it had extra considerations for scalability, residence, throttling, etc, which I remove to only highlight the usage of partial application. I haven't either displayed the implementation of some of the functions for simplicity but you can imagine how they look like.

```python

def dump_data_from_service(write_to_db,read_from_service, data_ids_to_read):
    for data_id in data_ids_read:
       data =  read_from_service(data_id)
       data_with_useful_formt = map_to_useful_format(data)
       write_to_db(data_with_useful_formt)

def write_to_db(get_db_connection, data):
    connection = get_db_connection()
    connection.write(data)

def read_from_services(read_from_service1, read_from_service2, read_from_service3, data_id):
    data_part_1 = read_from_service1(data_id)
    data_part_2 = read_from_service2(data_id)
    data_part_3 = read_from_service3(data_id)
    return combine_all_parts(data_part_1,data_part_2,data_part_2,data_part_3)

def main():
    data_ids_to_read = [.....]
    write_to_sql_db = partial(write_to_db,get_sql_connection)
    read_from_services = partial(read_from_services,read_from_serviceA,read_from_serviceB,reas_from_serviceB)
    dump_data_from_service(write_to_sql_db,read_from_services,data_ids_to_read)

```
Notice the usage of partial application in the ```main()``` function. I am basically putting together multiple functions by partially apply them with their dependencies. It is similar to what we know as [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) but with only functions. I mainly did this so I can easily write tests by mocking dependencies

# Searching most popular Python repositories on Github
For this article I did a search on 100+ Python repositories on Github which had more than 100 stars and at least used ``partial`` keyword once over the whole repository. Here is the [source code](https://github.com/samousavih/github-search/blob/main/README.md) used for this article.
I have short-listed well-known repositories e.g. pip, Panda, Conda, etc. In some repositories partial application was used multiple times but I only picked one use case. Additionally, in many repos the usage of the technique was not very interesting or it was complicated and not suitable to be discussed here. I also, prioritised the samples which partial application was pivotal for the core problem that the repository was solving.

# Dry run of Conda commands
[Conda](https://github.com/conda/conda/tree/main) is a popular package manager. With Conda you can create multiple independent python environments and switch between them when needed. There is also a dry run option which you can use to see how each of Conda's commands would impact the current environment setup. The interesting command we study here is ``Conda rename``. [This command](https://docs.conda.io/projects/conda/en/latest/commands/rename.html) would change the name of an environment. See below a sample usage of this command,
```sh
$ Conda rename -n oldname newname
```
The command has several options, one of them is dry run ``-d``, which prints a preview of what would the command do without actually applying the changes. Let see an example,
```sh
$ conda rename -n oldname newname -d

Dry run action: clone /usr/local/Caskroom/miniconda/base/envs/oldname,/usr/local/Caskroom/miniconda/base/envs/newname
Dry run action: rm_rf /usr/local/Caskroom/miniconda/base/envs/oldname

```
As you see above dry run shows two actions:

1) Cloning the current environment to a new path with the new name
2) Removing current environment 

Now let's have a look at Conda's source code. Rename command has been implemented [main_rename.py](https://github.com/conda/conda/blob/e69b2353c2f14fbfc9fd3aa448ebc991b28ca136/conda/cli/main_rename.py#L127). The following is a code extract from the file,
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

# Resilient bidirectional mapping in bidict
[bidict](https://github.com/jab/bidict/) is a Python library designed for bidirectional mapping between keys and values. 
With bidict, two sets (dicts) are employed to manage relationships in both directions: from keys to values and vice versa. This bidirectional capability is handy in scenarios where maintaining consistency between the two sets is crucial.
bidict can handle update failures gracefully, following a [fails clean](https://bidict.readthedocs.io/en/main/basic-usage.html#updates-fail-clean) approach. In the event of an error during an update operation, bidict automatically rolls back the changes, preventing partial updates and maintaining a consistent state.
The following is an example of how the library would gracefully handle a key duplication,

```python
b = bidict({1: 'one', 2: 'two'})
b.putall([(3, 'three'), (1, 'uno')])

# (1, 'uno') was the problem...
b  # ...but (3, 'three') was not added either:
bidict({1: 'one', 2: 'two'})
```
As seen above ```putall``` is a function to insert a list of key/value items into bidict. In the case above key "1" was duplicated therefore non of the items would be inserted.To achieve that the insertion of "(3, 'three')" would be reverted.

Now lets look under the hood of the library. ```_perp_write``` is the [function]([https://github.com/jab/bidict/blob/7ed2ce59738a1127375ca25a2f8b2c7437514478/bidict/_base.py#L389]) which prepares the operations needed for write upfront.
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
Before each write operation, bidict prepares operations for both writing and unwriting, see ```write``` and ```unwrite``` lists in the code above.
These operations serve as a set of instructions to update both ```self._fwdm``` and ```self._invm```  which are the bot sets bidict uses to be bidirectional. In case of a failure during the update, bidict seamlessly rolls back these operations, preventing any partial or inconsistent changes by running all of operations in ```unwrite``` list.
All of the operations in those two lists are pre-setup using partial application. The functions which do the actual writing are ```fwdm_set``` for updating the forward dictionary and ```invm_set``` for updating the inverse one. 
As observed, partial application plays an important role in this design and makes it easier to create the both lists of write and unwrite operations.

# Pre-configuration of options for pip
[Pip](https://pip.pypa.io/en/stable/) is another widely-used package installer (manager) for Python. Pip has many commands and each has several options. As an example  `-h` option is utilised to display the help information for the `pip install` command. Each option is represented as a class in Pip, providing a structured and modular approach to command-line options.
Pip initialises its options through the definition of classes, which can be seen in [cmdoptions.py](https://github.com/pypa/pip/blob/2a0acb595c4b6394f1f3a4e7ef034ac2e3e8c17e/src/pip/_internal/cli/cmdoptions.py#L121). These options are parsed and processed during various commands.
Options are defined globally so can be used and shared among commands, allowing for flexibility and code reuse. However, to ensure isolation between commands, options are not instantiated globally.
Here is an example code extract from Pip's source code "cmdoptions.py" showing the definition of two options : `help_` and `debug_mode`:

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

Notice how partial application helps with defining these options and freezing the parameters without needing to instantiate the options.

# JIT function decorator

[JAX](https://jax.readthedocs.io/) is a library commonly used for just-in-time (JIT) compilation in computations, particularly in performance-critical applications like deep learning. The `jax.jit` function is used for optimising functions on-the-fly.

The [official documentation for `jax.jit`](https://jax.readthedocs.io/en/latest/_autosummary/jax.jit.html#jax.jit) provides information on how to utilize JIT compilation.

JIT can be applied as a function decorator. A common practice is to use partial application when passing arguments to the JIT-compiled function. This allows users to customise the behavior by supplying specific arguments.

The `static_argnames` parameter in JIT helps with controlling when to recompile a function. By specifying which arguments are considered static, users can manage the trade-off between compilation overhead and performance gains. An example of using jit can be found in the source code [google-research repository](https://github.com/google-research/google-research/blob/70796b286879cf0fe27c66aa79c0a6413ab70a62/pvn/indicator_functions.py#L97).

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
In this example, the ``multiply_shift_hash_function`` is decorated with ``jax.jit`` using partial application.  ``static_argnames`` is set with ```('mersenne_prime_exponent', 'num_bins')``` which means each time the value of those arguments changes JIT would need to recompile the function.

For fun here is a benchmark to show how JIT improves computation time. In this example we calculating cube of elements in a matrix. This benchmark was done on a Mac with Intel CPU.
```python
import time
from jax import jit
import jax.numpy as jnp

def cube(x):
    return x * x * x

# generate data
x = jnp.ones((100000, 100000))

# create the jit version of the cube function
jit_cube = jit(cube)

# Measure the time taken by cube without jit
start_time = time.time()
cube(x)
end_time = time.time()
time_taken_function1 = end_time - start_time
print(f"Time taken by cube: {time_taken_function1} seconds")

# Measure the time taken by cube with jit
start_time = time.time()
jit_cube(x)
end_time = time.time()
time_taken_function2 = end_time - start_time
print(f"Time taken by jit_cube: {time_taken_function2} seconds")
```

```
Time taken by cube: 112.80942106246948 seconds
Time taken by jit_cube: 39.94196319580078 seconds
```

# Other findings which wasn't mentioned here
The above examples were only a few among many others. Other interesting cases I found were [Tensorflow](https://github.com/tensorflow/tensorflow/tree/master), [pytorch](https://github.com/pytorch/pytorch/blob/e66ec5843f6cc203de5570059794a3ae14dab4ae/torch/profiler/_utils.py#L24), [saleor](https://github.com/saleor/saleor/blob/d69bb446eff47a767903bdbe840b7db25532b3b0/saleor/discount/models.py#L133), and  [Home Assist ](https://github.com/home-assistant/core/blob/a8148cea65454b79b44ab1c7da15d9b57d39f805/homeassistant/components/dsmr/sensor.py#L589), but avoided adding them here as the article would be too long. Feel free to explore them yourself.

# Conclusion
1) counldn't find any dependency injection
2) Mostly was creating operations to use later
3) joy of learning new 
4) Double check our understanding with reality
5) Not easy to search using Apis
