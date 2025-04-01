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
4  print(power(3,2))  # Outputs 9
```

---
# What is Partial Function Application?

```python
1  from functools import partial
2  
3  power2 = partial(powern, n=2)
4  
5  print(power2(3))  # Outputs 9
```

---
# Conda
Dry run of Conda commands using partial application

```sh
$ Conda rename -n oldname newname
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
- Pre-configuration of options for commands without initialisation

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
Bidirectional Mapping with `bidict`

```python
1  from bidict import bidict
2
3  b = bidict(one=1, two=2, three=3)
4  print(b["one"])  # Outputs 1
5  print(b.inv[1])   # Outputs "one"
```

[Source Code](https://github.com/jab/bidict/blob/main/src/bidict/_base.py#L20)

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
# Bidict - PrepWrite Benefits
- Prepares all operations before execution
- Enables atomic updates
- Makes rollback possible on failures
- Maintains bidirectional consistency

---
# Bidict - putall Example
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
---
# Bidict - putall Internals
- Validates all operations first
- Creates write/unwrite operations for each pair
- On any error:
  - Stops further updates
  - Executes unwrite operations
  - Restores original state
---

# Other Findings
- TensorFlow, PyTorch and Home Assistant also use partial application.
- Each case solves unique problems like resilience, pre-configuration, and optimization.

---

# Conclusion
- Partial application is versatile in Python but not commonly used for dependency injection.
- Enables concise and modular code.

---

# Q&A
