---
title: Partial Function Application
paginate: true
theme: default
---

# Partial Function Application in Python
**A look under the hood of popular Python repositories on GitHub**

---

# What is Partial Function Application?

```python
1  def powern(x, n):    
2      return x**n
3  
4  print(power(2,3))  # Outputs 8
```

---
# What is Partial Function Application?

```python
1  from functools import partial
2  
3  power2 = partial(powern, x=2)
4  
5  print(power2(3))  # Outputs 8
```

---
# Popular repositories on Github 
- [Using GitHub Search Api](https://github.com/samousavih/github-search/blob/main/README.md)
- More than 100 stars
- Conda
- Pip
- bidict
---
# Conda
Dry run of Conda commands using partial application

```sh
$ conda rename -n oldname newname
```
```sh
$ conda rename -n oldname newname -d

  Dry run action: clone /path-to/oldname,/path-to/newname
  Dry run action: rm_rf /path-to/oldname
```

---
# Conda

```python
1   def clone_and_remove() 
2    actions = (
3        partial(install.clone, source, destination),
4        partial(rm_rf, source)
5    )
6    
7    for func in actions:
8        if args.dry_run:
9            print(f"{DRY_RUN_PREFIX} {func.func.__name__} {','.join(func.args)}")
10       else:
11           func()
```

[Source Code](https://github.com/conda/conda/blob/e69b2353c2f14fbfc9fd3aa448ebc991b28ca136/conda/cli/main_rename.py#L127)

---
# Pip
Command Options
```sh
$ pip install --help

```
```python
1  class Option:
2      def process(self, opt, value, values, parser):
3          #--------
4           elif action == "help":
5                parser.print_help()
6                parser.exit()
7          #--------

```

[Source Code](https://github.com/pypa/pip/blob/2a0acb595c4b6394f1f3a4e7ef034ac2e3e8c17e/src/pip/_internal/cli/cmdoptions.py#L121)

---
# Pip
Pre-configuration of options for commands without initialisation

```python
1  help_ = partial(
2      Option,
3      "-h",
4      "--help",
5      dest="help",
6      action="help",
7      help="Show help.",
8  )
```

[Source Code](https://github.com/pypa/pip/blob/2a0acb595c4b6394f1f3a4e7ef034ac2e3e8c17e/src/pip/_internal/cli/cmdoptions.py#L121)

---
# Bidict
- `bidict` provides a bidirectional mapping, allowing lookups in both directions.
- Useful for scenarios like encoding/decoding, where both forward and reverse mappings are needed.

```python
1  b["four"] = 4
2  print(b.inv[4])  # Outputs "four"
```

[Source Code](https://github.com/jab/bidict/blob/main/src/bidict/_base.py#L20)

---
# Bidict - putall
```python
b = bidict({1: 'one', 2: 'two'})

# Multiple updates - all or nothing
b.putall([
    (3, 'three'),  # Would succeed
    (1, 'uno'),    # Will fail (key exists)
    (4, 'four')    # Won't be attempted
])

# Result: b still equals {1: 'one', 2: 'two'}
```
----
# Bidict - putall 

```python
1  def _update():
2      unwrites = []
3      for key, val in iteritems(arg, **kw):
4          try:
5              dedup_result = self._dedup(key, val, on_dup)
6          except DuplicationError:
7              if rbof:
8                  while unwrites:
9                      for unwriteop in unwrites.pop():
10                         unwriteop()
11                 raise
12          if dedup_result is None:
13              continue
14          write, unwrite = prep_write(key, val, *dedup_result, save_unwrite=rbof)
15          for writeop in write:
16              writeop()
17          if rbof:
18              append_unwrite(unwrite)
```

[Source Code](https://github.com/jab/bidict/blob/main/src/bidict/_base.py#L200)

---
# Bidict - Inside PrepWrite
```python
1  def _prep_write(self):
2      fwdm_set, invm_set = fwdm.__setitem__, invm.__setitem__
3      write = [
4          partial(fwdm_set, newkey, newval),
5          partial(invm_set, newval, newkey),
6      ]
7      unwrite = [
8          partial(fwdm_del, newkey),
9          partial(invm_del, newval),
10     ]
11     return write, unwrite
```
---

# Other Findings
- [TensorFlow](https://github.com/tensorflow/tensorflow/tree/master)
- [PyTorch](https://github.com/pytorch/pytorch/blob/e66ec5843f6cc203de5570059794a3ae14dab4ae/torch/profiler/_utils.py#L24)
- [Home Assistant](https://github.com/home-assistant/core/blob/a8148cea65454b79b44ab1c7da15d9b57d39f805/homeassistant/components/dsmr/sensor.py#L589)

---
# Who am I?

<img align="center"  height="350" src="./profile.jpg">

<img align="right"  height="200" src="./image.png"> 

amin-mousavi.dev
Senior Software Engineer @ CBA


