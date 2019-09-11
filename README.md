A Jupyter notebook server with OCaml as a supported language.

```
docker build . -t jupyter-ocaml
docker run --rm -p 8888:8888 -v "$PWD":/home/jovyan/work jupyter-ocaml
```
