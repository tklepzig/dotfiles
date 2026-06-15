# Python

### Virtual environments

Create a venv in a `.venv` folder (isolated per-project package install):

    python3 -m venv .venv

Activate it (prepends `.venv/bin` to your `PATH` for this shell):

    source .venv/bin/activate

With the venv active, `pip` and `python` resolve to the ones inside `.venv` — install and run as usual:

    pip install requests
    python -m requests   # or: python my_script.py

Leave the venv when done:

    deactivate

Without activating, call the binaries directly via their path:

    .venv/bin/pip install requests
    .venv/bin/python my_script.py

### Browse any object in a graphical way

    pip install objexplore

    from objexplore import explore
    explore(any_object)
