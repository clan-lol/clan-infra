import logging

log = logging.getLogger(__name__)
import datetime
import time

import aiohttp
from nio import (
    AsyncClient,
    JoinResponse,
    MatrixRoom,
    RoomMessageText,
)

from matrix_bot.gitea import (
    GiteaData,
    PullState,
    fetch_pull_requests,
)

from . import BotConfig
from .locked_open import read_locked_file, write_locked_file
from .matrix import MatrixData, get_room_members, send_message


async def message_callback(room: MatrixRoom, event: RoomMessageText) -> None:
    log.debug(
        f"Message received in room {room.display_name}\n"
        f"{room.user_name(event.sender)} | {event.body}"
    )


async def send_error(client: AsyncClient, matrix: MatrixData, msg: str) -> None:
    # If you made a new room and haven't joined as that user, you can use
    room: JoinResponse = await client.join(matrix.review_room)
    if not room.transport_response.ok:
        log.error("This can happen if the room doesn't exist or the bot isn't invited")
        raise Exception(f"Failed to join room {room}")
    await send_message(client, room, msg, user_ids=[matrix.admin])


async def review_requested_bot(
    client: AsyncClient,
    http: aiohttp.ClientSession,
    matrix: MatrixData,
    gitea: GiteaData,
    bot_conf: BotConfig,
) -> None:
    # If you made a new room and haven't joined as that user, you can use
    room: JoinResponse = await client.join(matrix.review_room)

    if not room.transport_response.ok:
        log.error("This can happen if the room doesn't exist or the bot isn't invited")
        raise Exception(f"Failed to join room {room}")

    # Get the members of the room
    room_users = await get_room_members(client, room)

    # Fetch the pull requests
    tstart = time.time()
    pulls = await fetch_pull_requests(gitea, http, limit=50, state=PullState.ALL)

    # Read the last updated pull request
    ping_hist_path = bot_conf.data_dir / "last_review_run.json"
    ping_hist = read_locked_file(ping_hist_path)

    # Check if the pull request is mergeable and needs review
    # and if the pull request is newer than the last updated pull request
    for pull in pulls:
        requested_reviewers = pull["requested_reviewers"]
        assigned_users = pull["assignees"]
        mentioned_users = []
        if assigned_users:
            mentioned_users.extend(assigned_users)
        if requested_reviewers:
            mentioned_users.extend(requested_reviewers)

        mentioned_users = list(map(lambda x: x["login"].lower(), mentioned_users))
        mentioned_users = list(
            filter(lambda name: name not in matrix.user, mentioned_users)
        )
        pull_id = str(pull["id"])
        needs_review_label = any(
            x["name"] in gitea.mention_labels for x in pull["labels"]
        )
        if (len(mentioned_users) > 0 and pull["mergeable"]) or (
            needs_review_label and pull["mergeable"]
        ):
            # Mention the pull request again if it has been updated
            if gitea.mention_on_update:
                last_time_updated = ping_hist.get(pull_id, {}).get(
                    "updated_at", datetime.datetime.min.isoformat()
                )
                if ping_hist == {} or pull["updated_at"] > last_time_updated:
                    ping_hist[pull_id] = pull
                else:
                    continue
            else:
                if ping_hist == {} or pull_id not in ping_hist:
                    ping_hist[pull_id] = pull
                else:
                    continue

            # Check if the requested reviewers are in the room
            ping_users = []
            for user in room_users:
                user_name = user.display_name.lower()
                if any(
                    user_name in mentioned_user or mentioned_user in user_name
                    for mentioned_user in mentioned_users
                ):
                    ping_users.append(user.user_id)

            # Send a message to the room and mention the users
            log.info(f"Pull request {pull['title']} needs review")
            log.debug(
                f"Mentioned users: {mentioned_users}, has needs-review label: {needs_review_label}"
            )
            message = f"Review Requested:\n[{pull['title']}]({pull['html_url']})"
            await send_message(client, room, message, user_ids=ping_users)

    # Write the new last updated pull request
    write_locked_file(ping_hist_path, ping_hist)

    # Time taken
    tend = time.time()
    tdiff = round(tend - tstart)
    log.debug(f"Time taken: {tdiff}s")
