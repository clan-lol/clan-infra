import argparse
import asyncio
import logging
import os
import sys
from os import environ
from pathlib import Path

from matrix_bot.bot_conf import BotConfig
from matrix_bot.custom_logger import setup_logging
from matrix_bot.gitea import GiteaData
from matrix_bot.main import bot_main
from matrix_bot.matrix import MatrixData

log = logging.getLogger(__name__)

curr_dir = Path(__file__).parent
data_dir = Path(os.getcwd()) / "data"


def create_parser(prog: str | None = None) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog=prog,
        description="A gitea bot for matrix",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "--debug",
        help="Enable debug logging",
        action="store_true",
        default=False,
    )

    parser.add_argument(
        "--server",
        help="The matrix server to connect to",
        default="https://matrix.clan.lol",
    )
    parser.add_argument(
        "--admin",
        help="The matrix user to ping on error",
        default="@qubasa:gchq.icu",
    )

    parser.add_argument(
        "--user",
        help="The matrix user to connect as",
        default="@clan-bot:clan.lol",
    )

    parser.add_argument(
        "--avatar",
        help="The path to the image to use as the avatar",
        default=curr_dir / "avatar.png",
    )

    parser.add_argument(
        "--repo-owner",
        help="The owner of gitea the repository",
        default="clan",
    )
    parser.add_argument(
        "--repo-name",
        help="The name of the repository",
        default="clan-core",
    )

    parser.add_argument(
        "--changelog-room",
        help="The matrix room to join for the changelog bot",
        default="#bot-test:gchq.icu",
    )

    parser.add_argument(
        "--review-room",
        help="The matrix room to join for the review bot",
        default="#bot-test:gchq.icu",
    )

    parser.add_argument(
        "--changelog-frequency",
        help="The frequency to check for changelog updates in days",
        default=7,
        type=int,
    )

    def valid_weekday(value: str) -> str:
        days = [
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday",
        ]
        if value not in days:
            raise argparse.ArgumentTypeError(
                f"{value} is not a valid weekday. Choose from {', '.join(days)}"
            )
        return value

    parser.add_argument(
        "--publish-day",
        help="The day of the week to publish the changelog. Ignored if changelog-frequency is less than 7 days.",
        default="Wednesday",
        type=valid_weekday,
    )

    parser.add_argument(
        "--gitea-url",
        help="The gitea url to connect to",
        default="https://git.clan.lol",
    )

    parser.add_argument(
        "--data-dir",
        help="The directory to store data",
        default=data_dir,
        type=Path,
    )

    parser.add_argument(
        "--poll-frequency",
        help="The frequency to poll for new reviews in minutes",
        default=10,
        type=float,
    )

    parser.add_argument(
        "--disable-pr-bot",
        help="Disable the PR bot",
        action="store_true",
    )
    parser.add_argument(
        "--disable-changelog-bot",
        help="Disable the changelog bot",
        action="store_true",
    )
    parser.add_argument(
        "--pull-mention-every-update",
        help="Mention the user every time the PR is updated",
        action="store_true",
    )
    parser.add_argument(
        "--mention-labels",
        help="The labels that trigger a mention",
        nargs="+",
        default=["needs-review"],
    )

    return parser


def matrix_password() -> str:
    matrix_password = environ.get("MATRIX_PASSWORD")
    if matrix_password is not None:
        return matrix_password
    matrix_password_file = environ.get("MATRIX_PASSWORD_FILE", default=None)
    if matrix_password_file is None:
        raise Exception("MATRIX_PASSWORD_FILE environment variable is not set")
    with open(matrix_password_file) as f:
        return f.read().strip()


def main() -> None:
    parser = create_parser()
    args = parser.parse_args()

    if args.debug:
        setup_logging(logging.DEBUG, root_log_name=__name__.split(".")[0])
        log.debug("Debug log activated")
    else:
        setup_logging(logging.INFO, root_log_name=__name__.split(".")[0])

    bot_conf = BotConfig(
        data_dir=args.data_dir,
        disable_pr_bot=args.disable_pr_bot,
        disable_changelog_bot=args.disable_changelog_bot,
    )

    matrix = MatrixData(
        server=args.server,
        user=args.user,
        avatar=args.avatar,
        changelog_room=args.changelog_room,
        changelog_frequency=args.changelog_frequency,
        publish_day=args.publish_day,
        review_room=args.review_room,
        password=matrix_password(),
        admin=args.admin,
    )

    gitea = GiteaData(
        url=args.gitea_url,
        owner=args.repo_owner,
        repo=args.repo_name,
        access_token=os.getenv("GITEA_ACCESS_TOKEN"),
        poll_frequency=args.poll_frequency,
        mention_on_update=args.pull_mention_every_update,
        mention_labels=args.mention_labels,
    )

    bot_conf.data_dir.mkdir(parents=True, exist_ok=True)

    try:
        asyncio.run(bot_main(matrix, gitea, bot_conf))
    except KeyboardInterrupt:
        print("User Interrupt", file=sys.stderr)


if __name__ == "__main__":
    main()
