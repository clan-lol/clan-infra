import argparse
import json
import urllib.error
import urllib.request
from os import environ
from typing import Optional


def load_token() -> str:
    GITEA_TOKEN_FILE = environ.get("GITEA_TOKEN_FILE", default=None)
    assert GITEA_TOKEN_FILE is not None
    with open(GITEA_TOKEN_FILE, "r") as f:
        return f.read().strip()


def pr_message(pr: dict) -> str:
    return f"PR {pr['number']} in repo {pr['base']['repo']['name']} from user {pr['user']['login']}: {pr['title']}"


def is_ci_green(pr: dict) -> bool:
    print(f"Checking CI status for {pr_message(pr)}")
    repo = pr["base"]["repo"]["name"]
    url = (
        "https://git.clan.lol/api/v1/repos/clan/"
        + repo
        + "/commits/"
        + pr["head"]["sha"]
        + "/status"
    )
    response = urllib.request.urlopen(url)
    data = json.loads(response.read())
    # check for all commit statuses to have status "success"
    if not data["statuses"]:
        print(f"No CI status for {pr_message(pr)}")
        return False
    for status in data["statuses"]:
        if status["status"] != "success":
            return False
    return True


def is_org_member(user: str, token: str) -> bool:
    url = "https://git.clan.lol/api/v1/orgs/clan/members/" + user + f"?token={token}"
    try:
        urllib.request.urlopen(url)
        return True
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        else:
            raise


def merge_allowed(pr: dict, bot_name: str, token: str) -> bool:
    assignees = pr["assignees"] if pr["assignees"] else []
    if (
        is_org_member(pr["user"]["login"], token)
        and pr["mergeable"] is True
        and not pr["title"].startswith("WIP:")
        and pr["state"] == "open"
        # check if bot is assigned
        and any(assignee["login"] == bot_name for assignee in assignees)
        and is_ci_green(pr)
    ):
        return True
    return False


# python equivalent for: curl -X 'GET' https://git.clan.lol/api/v1/repos/clan/{repo}/pulls
def list_prs(repo: str) -> list:
    url = "https://git.clan.lol/api/v1/repos/clan/" + repo + "/pulls"
    response = urllib.request.urlopen(url)
    data = json.loads(response.read())
    return data


def list_prs_to_merge(prs: list, bot_name: str, gitea_token: str) -> list:
    prs_to_merge = []
    for pr in prs:
        if merge_allowed(pr, bot_name, gitea_token):
            prs_to_merge.append(pr)
    return prs_to_merge


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Merge PRs on clan.lol")
    # parse a list of allowed users
    # option for bot-name
    parser.add_argument(
        "--bot-name",
        help="name of the bot",
        required=True,
    )
    # parse list of repository names for which to merge PRs
    parser.add_argument(
        "--repos",
        nargs="+",
        help="list of repositories for which to merge PRs",
        required=True,
    )
    # option for dry run
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="dry run",
    )
    return parser.parse_args()


def clan_merge(
    args: Optional[argparse.Namespace] = None, gitea_token: Optional[str] = None
) -> None:
    if gitea_token is None:
        gitea_token = load_token()
    if args is None:
        args = parse_args()
    repos = args.repos
    dry_run = args.dry_run
    bot_name = args.bot_name
    for repo in repos:
        prs = list_prs(repo)
        prs_to_merge = list_prs_to_merge(prs, bot_name, gitea_token)
        for pr in prs_to_merge:
            url = (
                "https://git.clan.lol/api/v1/repos/clan/"
                + repo
                + "/pulls/"
                + str(pr["number"])
                + "/merge"
                + f"?token={gitea_token}"
            )
            if dry_run is True:
                print(f"Would merge {pr_message(pr)}")
            else:
                print(f"Merging {pr_message(pr)}")
                data = dict(
                    Do="rebase",
                )
                data_encoded = json.dumps(data).encode("utf8")
                req = urllib.request.Request(
                    url, data=data_encoded, headers={"Content-Type": "application/json"}
                )
                urllib.request.urlopen(req)


if __name__ == "__main__":
    clan_merge()
