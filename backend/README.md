# How to run

## Create virtual environment

Windows: `python -m venv venv`
Linux: `python3 -m venv venv`

## Activate it

Windows: `venv\Scripts\activate`
Linux: `source venv/bin/activate`

## Install dependencies

`pip install -r requirements.txt`

## Initilize database

Find `schema.sql` in `/database/schema.sql` and place in this folder
Run: `python init_db.py`

## Run the app

`python app.py`
Note: Linux might need `python3 app.py`

By default the app will run on:
`http://127.0.0.1:5000`
