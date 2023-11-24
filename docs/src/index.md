```@meta
CurrentModule = TaijaInteroperability
```

# TaijaInteroperability

Documentation for [TaijaInteroperability](https://github.com/JuliaTrustworthyAI/TaijaInteroperability.jl).

A package for enabling interoperability between Python and R machine learning models with Taija.

## Importing PyTorch models

The package combined with CounterfactualExplanations supports generating counterfactuals for any neural network that has been previously defined and trained using PyTorch, regardless of the specific architectural details of the model. To generate counterfactuals for a PyTorch model, save the model inside a `.pt` file and call the following function:

``` julia
model_loaded = TaijaInteroperability.pytorch_model_loader(
    "$(pwd())/docs/src/tutorials/miscellaneous",
    "neural_network_class",
    "NeuralNetwork",
    "$(pwd())/docs/src/tutorials/miscellaneous/pretrained_model.pt"
)
```

The method `pytorch_model_loader` requires four arguments:
1. The path to the folder with a `.py` file where the PyTorch model is defined
2. The name of the file where the PyTorch model is defined
3. The name of the class of the PyTorch model
4. The path to the Pickle file that holds the model weights

In the above case:
1. The file defining the model is inside `$(pwd())/docs/src/tutorials/miscellaneous`
2. The name of the `.py` file holding the model definition is `neural_network_class`
3. The name of the model class is NeuralNetwork
4. The Pickle file is located at `$(pwd())/docs/src/tutorials/miscellaneous/pretrained_model.pt`

Though the model file and Pickle file are inside the same directory in this tutorial, this does not necessarily have to be the case.

The reason why the model file and Pickle file have to be provided separately is that the package expects an already trained PyTorch model as input. It is also possible to define new PyTorch models within the package, but since this is not the expected use of the package, special support is not offered for that. A guide for defining Python and PyTorch classes in Julia through `PythonCall.jl` can be found [here](https://cjdoris.github.io/PythonCall.jl/stable/pythoncall-reference/#Create-classes).

Once the PyTorch model has been loaded into the package, wrap it inside the PyTorchModel class:

``` julia
model_pytorch = TaijaInteroperability.PyTorchModel(model_loaded, counterfactual_data.likelihood)
```

This model can now be passed into the generators like any other as described in the CounterfactualExplanations  documentation.

Please note that the functionality for generating counterfactuals for Python models is only available if your Julia version is 1.8 or above. For Julia 1.7 users, we recommend upgrading the version to 1.8 or 1.9 before loading a PyTorch model into the package.

## Importing R torch models

>   Please note that due to the incompatibility between RCall and PythonCall, it is not feasible to test both PyTorch and RTorch implementations within the same pipeline. While the RTorch implementation has been manually tested, we cannot ensure its consistent functionality as it is inherently susceptible to bugs.

The TaijaInteroperability package combined with CounterfactualExplanations package supports generating counterfactuals for neural networks that have been defined and trained using R torch. Regardless of the specific architectural details of the model, you can easily generate counterfactual explanations by following these steps.

### Saving the R torch model

First, save your trained R torch model as a `.pt` file using the `torch_save()` function provided by the R torch library. This function allows you to serialize the model and save it to a file. For example:

``` r
torch_save(model, file = "$(pwd())/docs/src/tutorials/miscellaneous/r_model.pt")
```

Make sure to specify the correct file path where you want to save the model.

### Loading the R torch model

To import the R torch model into the CounterfactualExplanations package, use the `rtorch_model_loader()` function. This function loads the model from the previously saved `.pt` file. Here is an example of how to load the R torch model:

``` julia
model_loaded = TaijaInteroperability.rtorch_model_loader("$(pwd())/docs/src/tutorials/miscellaneous/r_model.pt")
```

The `rtorch_model_loader()` function requires only one argument:
1. `model_path`: The path to the `.pt` file that contains the trained R torch model.

### Wrapping the R torch model

Once the R torch model has been loaded into the package, wrap it inside the `RTorchModel` class. This step prepares the model to be used by the counterfactual generators. Here is an example:

``` julia
model_R = TaijaInteroperability.RTorchModel(model_loaded, counterfactual_data.likelihood)
```

### Generating counterfactuals with the R torch model

Now that the R torch model has been wrapped inside the `RTorchModel` class, you can pass it into the counterfactual generators as you would with any other model.

Please note that RCall is not fully compatible with PythonCall. Therefore, it is advisable not to import both R torch and PyTorch models within the same Julia session. Additionally, it’s worth mentioning that the R torch integration is still untested in the CounterfactualExplanations package.

```@autodocs
Modules = [TaijaInteroperability]
```
