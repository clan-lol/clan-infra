import fcntl
import json
from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path
from typing import Any


@contextmanager
def locked_open(filename: str | Path, mode: str = "r") -> Generator:
    """
    This is a context manager that provides an advisory write lock on the file specified by `filename` when entering the context, and releases the lock when leaving the context. The lock is acquired using the `fcntl` module's `LOCK_EX` flag, which applies an exclusive write lock to the file.
    """
    with open(filename, mode) as fd:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield fd
        fcntl.flock(fd, fcntl.LOCK_UN)


def write_locked_file(path: Path, data: dict[str, Any]) -> None:
    with locked_open(path, "w+") as f:
        f.write(json.dumps(data, indent=4))


def read_locked_file(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with locked_open(path, "r") as f:
        content: str = f.read()
        parsed: dict[str, Any] = json.loads(content)
        return parsed
