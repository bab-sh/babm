# babm

[![CI](https://github.com/bab-sh/babm/actions/workflows/ci.yml/badge.svg)](https://github.com/bab-sh/babm/actions/workflows/ci.yml)
[![PyPI version](https://badge.fury.io/py/babm.svg)](https://badge.fury.io/py/babm)
[![Python Versions](https://img.shields.io/pypi/pyversions/babm.svg)](https://pypi.org/project/babm/)

CLI Migration tool for Babfile and other task runner formats.

## Installation

### Quick Install (recommended)

**macOS / Linux:**
```bash
curl -fsSL https://babm.bab.sh/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://babm.bab.sh/install.ps1 | iex
```

### PyPI

```bash
pip install babm
```

### Standalone Binary

Download from the [releases page](https://github.com/bab-sh/babm/releases).

## Development

```bash
git clone https://github.com/bab-sh/babm.git
cd babm
uv sync
uv run pytest
```