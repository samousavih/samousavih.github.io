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
3) What is __new__ and __call__ 
4) is it different in CPython and other Python implementations?
5) what is Modules/_functoolsmodule.c vs Lib/functools.py which one is the implementation? 
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
