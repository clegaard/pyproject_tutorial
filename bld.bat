# Install package using Setuptools, but omitting the dependencies specified by the pyproject.toml file since these are installed by conda.
"%PYTHON%" -m pip install %RECIPE_DIR% --no-deps
if errorlevel 1 exit 1