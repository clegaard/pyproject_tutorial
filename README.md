# Sharing pyproject.toml between Pip and Conda

**The code for this project can be found in www.github.com/clegaard/pyproject_tutorial.git

## The new format for building Python libraries
The `pyproject.toml` is a new type of configuration file used by [Setuptools](https://setuptools.pypa.io/en/latest/index.html), [Poetry](https://python-poetry.org/) or [Flit](https://pypi.org/project/flit/).
The format was introduced in [PEP 518](https://peps.python.org/pep-0518/), and have since been extended by [PEP 517](https://peps.python.org/pep-0517/), [PEP 621](https://peps.python.org/pep-0621/) and [PEP 660](https://peps.python.org/pep-0660/).



## Writing a simple library

For sake of simplicty, we will define a package with two modules `foo` and `bar`, defined as follows:
``` python
# mypackage/foo.py
def print_foo():
    print("foo")
```
and
``` python
# mypackage/bar.py
def print_bar():
    print("foo")
```
We also define a `__init__.py` file in the root of the module:
``` python
# mypackge/__init__.py
import importlib.metadata
__version__ = importlib.metadata.version("mypackage")
```
The purpose is to let us set the version attribute based on the version number defined in the `pyproject.toml` file.
It is also possible to set the `__version__` attribute in the script and have the Setuptools read this info when installing. However, I did not find a way to parse the information in Conda from the `__init__.py` file.

The final file layout should look like:
```
├── mypackage
│   ├── bar.py
│   ├── foo.py
│   └── __init__.py
└── pyproject.toml
```

## Pip

``` bash
python3 -m pip install --upgrade pip # make sure that pip is at the latest version
python3 -m pip install .
```

## Anaconda

Anaconda provides a package manager and a means for creating virtual environments.
A natural question to asks is if the information from the `pyproject.toml` can be used to install packages using Conda.
Unfortunately there are a few challenges to doing this, see [Conda Issue Tracker](https://github.com/conda/conda/issues/10633).
To summarize the issue, Conda:
* Does not use PyPI, which means that not all packages may be available, or they may be published under a different name. There is no way of converting Conda package names based PyPI names, other than applying heuristics.
* Is designed to manage non-python packages, such as compilers, which is not a concept that can be expressed in `pyproject.toml`


Backend specific information can be expressed in the `pyproject.toml`, so it would in theory be possible for Conda to adopt the format and specific the own version of dependencies, while keeping common metadate like the version number, description and authors.
However, this is likely to take a long time, if it even happens at all.

In the meantime, we can find a way to share as much information between the two files as possible.
Fortunately, the Conda developers has seen the writing on the wall and provide a set of functions we can use inside the `meta.yaml`, see [loading data from other files](https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html#loading-data-from-other-files).

We can use this to read and parse the `pyprojec.yaml` and render this using the [Jinja](https://jinja.palletsprojects.com/en/latest/) based templating mechanism build into Conda.

``` jinja
# it seems that `load_file_data` requires an absolute path, unlike what their documentation shows:
# https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html#loading-data-from-other-files
{% set path = os.path.join(os.environ.get('PWD'),"pyproject.toml")%}
{% set pyproject = load_file_data(path) %}
{% set pyproject = load_file_data(path) %}

# with the pyproject.toml loaded we can extract the information needed in order to avoid duplication
{% set version = pyproject.get('project').get('version')%}
{% set name = pyproject.get('project').get('name')%}

package:
  name: {{name}}
  version: {{ version }}

requirements:
  run:
    - numpy
  build:
    - python
    - setuptools

test:
  requirements:
    - pytest
    - hypothesis
  
```

To build the project with Conda we need to install a few dependencies:
``` bash
conda install conda-build conda-verify
conda update --all
conda build .
conda install --use-local mypackage
```

