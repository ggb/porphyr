# Porphyr

** TODO: Add description **

## Examples

First, create some input data. **Porphyr** expects to get data as a list of tuples, where the first element is a concepts label and the second element is the concepts descriptor. (Actually you only need the descriptor.) You can use the (aleph)[https://github.com/ggb/aleph]-module to read in a text, identify concepts and output data in the right format. 

```bash
iex(1)> concepts = Aleph.Entities.get(text)
```

Then you need an empty hierarchy-structure. **Porphyr** ships with (ParseSKOS)[https://github.com/ggb/parseSKOS] as dependency. Create a hierarchy (which represents the Computer Classification System-vocabluary) with the following statement.

```bash
iex(2)> hierarchy = ParseSKOS.ParseTurtle.get(:ccs)
```

Start spreading activation with the Base Activation-method as follows:

```bash
iex(3)> Porphyr.Activation.get(concepts, hierarchy, :base)
```

Or use the Branch Activation-method.

```bash
iex(4)> Porphyr.Activation.get(concepts, hierarchy, :branch)
```

The decay-factor is by default set to .4, but you can easily change the value by setting the last parameter.

```bash
iex(5)> Porphyr.Activation.get(concepts, hierarchy, :branch, 0.1)
```

If you would like to do something fancy, try the *OneHop* Activation. *OneHop* is implemented in another module. 

```bash
iex(6)> Porphyr.OneHop.get(concepts, hierarchy)
```
