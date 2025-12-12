from typing import Annotated

import typer
from rich.console import Console

from babm import __version__

app = typer.Typer(
    name="babm",
    help="CLI Migration tool for Babfile and other task runner formats.",
    add_completion=True,
    no_args_is_help=True,
)

console = Console()


def version_callback(value: bool) -> None:
    if value:
        console.print(f"babm version: {__version__}")
        raise typer.Exit()


@app.callback()
def main(
    version: Annotated[
        bool | None,
        typer.Option(
            "--version",
            "-V",
            callback=version_callback,
            is_eager=True,
            help="Show version and exit.",
        ),
    ] = None,
) -> None:
    pass


if __name__ == "__main__":
    app()
