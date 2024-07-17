import asyncio
import datetime
import json
import logging
import shlex
import subprocess
from pathlib import Path

import aiohttp
from nio import (
    AsyncClient,
    JoinResponse,
)

from matrix_bot.gitea import (
    GiteaData,
)

from .locked_open import read_locked_file, write_locked_file
from .matrix import MatrixData, send_message
from .openai import create_jsonl_data, upload_and_process_files

log = logging.getLogger(__name__)


def last_ndays_to_today(ndays: int) -> tuple[str, str]:
    # Get today's date
    today = datetime.datetime.now()

    # Calculate the date one week ago
    last_week = today - datetime.timedelta(days=ndays)

    # Format both dates to "YYYY-MM-DD"
    todate = today.strftime("%Y-%m-%d")
    fromdate = last_week.strftime("%Y-%m-%d")

    return (fromdate, todate)


def write_file_with_date_prefix(
    content: str, directory: Path, *, ndays: int, suffix: str
) -> Path:
    """
    Write content to a file with the current date as filename prefix.

    :param content: The content to write to the file.
    :param directory: The directory where the file will be saved.
    :return: The path to the created file.
    """
    # Ensure the directory exists
    directory.mkdir(parents=True, exist_ok=True)

    # Get the current date
    fromdate, todate = last_ndays_to_today(ndays)

    # Create the filename
    filename = f"{fromdate}__{todate}_{suffix}.txt"
    file_path = directory / filename

    # Write the content to the file
    with open(file_path, "w") as file:
        file.write(content)

    return file_path


async def git_pull(repo_path: Path) -> None:
    cmd = ["git", "pull"]
    log.debug(f"Running command: {shlex.join(cmd)}")
    process = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(repo_path),
    )
    await process.wait()


async def git_log(repo_path: Path, ndays: int) -> str:
    cmd = [
        "git",
        "log",
        f"--since={ndays} days ago",
        "--pretty=format:%h - %an, %ar : %s",
        "--stat",
        "--patch",
    ]
    log.debug(f"Running command: {shlex.join(cmd)}")
    process = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(repo_path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await process.communicate()

    if process.returncode != 0:
        raise Exception(
            f"Command '{' '.join(cmd)}' failed with exit code {process.returncode}"
        )

    return stdout.decode()


async def changelog_bot(
    client: AsyncClient,
    http: aiohttp.ClientSession,
    matrix: MatrixData,
    gitea: GiteaData,
    data_dir: Path,
) -> None:
    last_run_path = data_dir / "last_changelog_run.json"
    last_run = read_locked_file(last_run_path)

    today = datetime.datetime.now()
    today_weekday = today.strftime("%A")

    if today_weekday != matrix.publish_day:
        log.debug(f"Changelog not due yet. Due on {matrix.publish_day}")
        return

    if last_run == {}:
        log.debug(f"First run. Setting last_run to {last_run}")
    else:
        last_date = datetime.datetime.strptime(last_run["todate"], "%Y-%m-%d")
        upper_bound = datetime.timedelta(days=matrix.changelog_frequency)
        delta = today - last_date
        if delta <= upper_bound:
            log.debug(
                f"Changelog not due yet. Due in {upper_bound.days - delta.days} days"
            )
            return

    fromdate, todate = last_ndays_to_today(matrix.changelog_frequency)
    last_run = {
        "fromdate": fromdate,
        "todate": todate,
        "ndays": matrix.changelog_frequency,
    }

    # If you made a new room and haven't joined as that user, you can use
    room: JoinResponse = await client.join(matrix.changelog_room)

    if not room.transport_response.ok:
        log.error("This can happen if the room doesn't exist or the bot isn't invited")
        raise Exception(f"Failed to join room {room}")

    repo_path = data_dir / gitea.repo

    if not repo_path.exists():
        cmd = [
            "git",
            "clone",
            f"{gitea.url}/{gitea.owner}/{gitea.repo}.git",
            gitea.repo,
        ]
        subprocess.run(cmd, cwd=data_dir, check=True)

    # git pull
    await git_pull(repo_path)

    # git log
    diff = await git_log(repo_path, matrix.changelog_frequency)

    fromdate, todate = last_ndays_to_today(matrix.changelog_frequency)
    log.info(f"Generating changelog from {fromdate} to {todate}")

    # Write the last run to the file before processing the changelog
    # This ensures that the changelog is only generated once per period
    # even if openai fails
    write_locked_file(last_run_path, last_run)

    system_prompt = f"""
Create a concise changelog
Follow these guidelines:

- Keep the summary brief
- Follow the pull request format: "scope: message (#number1, #number2)"
    - Don't use the commit messages tied to a pull request as is and instead explain the change in a user-friendly way
- Link pull requests as: '{gitea.url}/{gitea.owner}/{gitea.repo}/pulls/<number>'
    - Use markdown links to make the pull request number clickable
- Mention each pull request number at most once
- Focus on new clan modules if any
- Always use four '#' for headings never less than that. Example: `####New Features`
---
Example Changelog:
#### Changelog:
For the last {matrix.changelog_frequency} days from {fromdate} to {todate}
#### New Features
- `secrets`: Users can now generate secrets and manage settings in the new submodules [#1679]({gitea.url}/{gitea.owner}/{gitea.repo}/pulls/1679)  
- `sshd`: A workaround has been added to mitigate the security vulnerability [#1674]({gitea.url}/{gitea.owner}/{gitea.repo}/pulls/1674)  
...
#### Refactoring
...
#### Documentation
...
#### Bug Fixes
...
#### Additional Notes
...
---
#### Changelog:
For the last {matrix.changelog_frequency} days from {fromdate} to {todate}
#### New Features
    """

    # Step 1: Create the JSONL file
    jsonl_files = await create_jsonl_data(user_prompt=diff, system_prompt=system_prompt)

    # Step 2: Upload the JSONL file and process it
    results = await upload_and_process_files(session=http, jsonl_files=jsonl_files)

    # Join responses together
    all_changelogs = []
    for result in results:
        choices = result["response"]["body"]["choices"]
        changelog = "\n".join(choice["message"]["content"] for choice in choices)
        all_changelogs.append(changelog)
    full_changelog = "\n\n".join(all_changelogs)

    combine_prompt = """
Please combine the following changelogs into a single markdown changelog.
- Merge the sections and remove any duplicates.
- Make sure the changelog is concise and easy to read.
---
Example Changelog:
#### Changelog:
For the last {matrix.changelog_frequency} days from {fromdate} to {todate}
#### New Features
- **inventory**:
  - Initial support for deployment info for machines [#1767](https://git.clan.lol/clan/clan-core/pulls/1767)
  - Automatic inventory schema checks and runtime assertions [#1753](https://git.clan.lol/clan/clan-core/pulls/1753)
- **webview**:
  - Introduced block devices view and machine flashing UI [#1745](https://git.clan.lol/clan/clan-core/pulls/1745), [#1768](https://git.clan.lol/clan/clan-core/pulls/1768)
  - Migration to solid-query for improved resource fetching & caching [#1755](https://git.clan.lol/clan/clan-core/pulls/1755)
...
#### Refactoring
...
#### Documentation
...
#### Bug Fixes
...
#### Additional Notes
...
---
#### Changelog:
For the last {matrix.changelog_frequency} days from {fromdate} to {todate}
#### New Features
"""
    new_jsonl_files = await create_jsonl_data(
        user_prompt=full_changelog, system_prompt=combine_prompt
    )
    new_results = await upload_and_process_files(
        session=http, jsonl_files=new_jsonl_files
    )

    new_all_changelogs = []
    for result in new_results:
        choices = result["response"]["body"]["choices"]
        changelog = "\n".join(choice["message"]["content"] for choice in choices)
        new_all_changelogs.append(changelog)
    new_full_changelog = "\n\n".join(new_all_changelogs)
    log.info(f"Changelog generated:\n{new_full_changelog}")

    # Write the results to a file in the changelogs directory
    new_result_file = write_file_with_date_prefix(
        json.dumps(new_results, indent=4),
        data_dir / "changelogs",
        ndays=matrix.changelog_frequency,
        suffix="result",
    )
    log.info(f"LLM result written to: {new_result_file}")

    await send_message(client, room, new_full_changelog)
