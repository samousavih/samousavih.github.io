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


# Why would you want to use partial application?

## easier to pass or return functions by baking in arguments and dependencies

a (practical example)[https://github.com/SamsungLabs/fastflow-tensorflow/blob/8dc4caf647dc2df3c9fbe6c15bc7377baa8db1d6/tensorflow/python/ops/nn_ops.py#L2052C11-L2052C11] 
look how tenserflow returns passes a function but bakes in some of it's argument, 
```python

### the example might be hard to grasp find an easier one
return squeeze_batch_dims(
      input,
      functools.partial(
          gen_nn_ops.conv2d,
          filter=filter,
          strides=strides,
          padding=padding,
          use_cudnn_on_gpu=use_cudnn_on_gpu,
          explicit_paddings=explicit_paddings,
          data_format=data_format,
          dilations=dilations),
      inner_rank=3,
      name=name)
```

```Python
 return conv2d(input,
                filters,
                strides,
                padding,
                use_cudnn_on_gpu=True,
                data_format=data_format,
                dilations=dilations,
                name=name)
```

an example of returning a function [https://github.com/mesurendra/tensorflow/blob/a5120db4d6917f943176ef3c5bb938064604c761/tensorflow/python/ops/lookup_ops.py#L985]

### Overriding the default behavior of a method

example here 
https://github.com/pandas-dev/pandas/blob/2d2d67db48413fde356bce5c8d376d5b9dd5d0c2/pandas/io/sql.py#L1037

 we can override the way insert happens by passing a function


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

# Performance drawbacks

# How they work under the hood

# Other ways which might give you the same result

using code search

```
/=\s*(?:partial|functools\.partial)\s*\(/ NOT tensorflow NOT is:fork
```


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
