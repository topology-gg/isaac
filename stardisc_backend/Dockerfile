FROM python:3.9-buster

WORKDIR /app

COPY src .
COPY poetry.lock .
COPY pyproject.toml .

RUN python3 -m pip install poetry==1.4.0
RUN python3 -m pip install pycryptodome
RUN poetry config virtualenvs.create false
RUN poetry install --only main

ENTRYPOINT [ "indexer" ]