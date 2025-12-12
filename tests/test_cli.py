from typer.testing import CliRunner

from babm import __version__
from babm.cli import app


def test_version(cli_runner: CliRunner) -> None:
    result = cli_runner.invoke(app, ["--version"])
    assert result.exit_code == 0
    assert __version__ in result.stdout


def test_version_short(cli_runner: CliRunner) -> None:
    result = cli_runner.invoke(app, ["-V"])
    assert result.exit_code == 0
    assert __version__ in result.stdout


def test_help(cli_runner: CliRunner) -> None:
    result = cli_runner.invoke(app, ["--help"])
    assert result.exit_code == 0
    assert "babm" in result.stdout


def test_no_args_shows_help(cli_runner: CliRunner) -> None:
    result = cli_runner.invoke(app, [])
    assert result.exit_code == 2
    assert "Usage" in result.stdout
