# Leadbox Web QA Scanner

A Robot Framework project that scans an entire website using its /sitemap endpoint.

# How to install

## Install venv

```
sudo apt install python3-venv -y
```

## Create a virtual environment

```
python3 -m venv venv
```

## Open the virtual environment

### Windows
```
venv\Scripts\activate
```

### Linux
```
source venv/bin/activate
```

## Install all Robot Framework dependencies
```
pip install robotframework robotframework-seleniumlibrary robotframework-requests
```

# Features

https://docs.google.com/spreadsheets/d/1U9pzwQGB7i4cWUvZQ-MlXfCWjA0rTN2VM3vmwdSunMQ/edit?gid=1556919322#gid=1556919322

# Project structure

web-scanner/
│  README.md
│  pyproject.toml  (or requirements.txt)
│
├─ resources/
│    sitemap.robot
│    link_checker.robot
│    content_checker.robot
│    visual_checker.robot
│
├─ tests/
│    run_full_scan.robot
│
└─ libs/
     sitemap_parser.py