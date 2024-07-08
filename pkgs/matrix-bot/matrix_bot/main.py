import asyncio
import logging
from pathlib import Path

import aiohttp

log = logging.getLogger(__name__)

from nio import AsyncClient, ClientConfig, ProfileGetAvatarResponse, RoomMessageText

from .changelog_bot import changelog_bot
from .gitea import GiteaData
from .matrix import MatrixData, set_avatar, upload_image
from .review_bot import message_callback, review_requested_bot, send_error


async def bot_main(
    matrix: MatrixData,
    gitea: GiteaData,
    data_dir: Path,
) -> None:
    # Setup client configuration to handle encryption
    client_config = ClientConfig(
        encryption_enabled=False,
    )

    log.info(f"Connecting to {matrix.server} as {matrix.user}")
    client = AsyncClient(matrix.server, matrix.user, config=client_config)
    client.add_event_callback(message_callback, RoomMessageText)

    result = await client.login(matrix.password)
    if not result.transport_response.ok:
        log.critical(f"Failed to login: {result}")
        exit(1)
    log.info(f"Logged in as {result}")

    avatar: ProfileGetAvatarResponse = await client.get_avatar()
    if not avatar.avatar_url:
        mxc_url = await upload_image(client, matrix.avatar)
        log.info(f"Uploaded avatar to {mxc_url}")
        await set_avatar(client, mxc_url)
    else:
        log.info(f"Bot already has an avatar {avatar.avatar_url}")

    try:
        async with aiohttp.ClientSession() as session:
            while True:
                try:
                    await changelog_bot(client, session, matrix, gitea, data_dir)
                except Exception as e:
                    log.exception(e)
                    await send_error(client, matrix, f"Changelog bot failed: {e}")

                try:
                    await review_requested_bot(client, session, matrix, gitea, data_dir)
                except Exception as e:
                    log.exception(e)
                    await send_error(
                        client, matrix, f"Review requested bot failed: {e}"
                    )

                await asyncio.sleep(60 * 5)
    except Exception as e:
        log.exception(e)
    finally:
        await client.close()
