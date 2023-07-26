import argparse
import json
import urllib.request
from os import environ
from typing import Optional


def load_token() -> str:
    GITEA_TOKEN_FILE = environ.get("GITEA_TOKEN_FILE", default=None)
    assert GITEA_TOKEN_FILE is not None
    with open(GITEA_TOKEN_FILE, "r") as f:
        return f.read().strip()


def is_ci_green(pr: dict) -> bool:
    print("Checking CI status for PR " + str(pr["id"]))
    url = (
        "https://git.clan.lol/api/v1/repos/clan/"
        + pr["base"]["repo"]["name"]
        + "/commits/"
        + pr["head"]["sha"]
        + "/status"
    )
    response = urllib.request.urlopen(url)
    data = json.loads(response.read())
    # check for all commit statuses to have status "success"
    for status in data["statuses"]:
        if status["status"] != "success":
            return False
    return True


def decide_merge(pr: dict, allowed_users: list[str]) -> bool:
    if (
        pr["user"]["login"] in allowed_users
        and pr["mergeable"] is True
        and not pr["title"].startswith("WIP:")
        and pr["state"] == "open"
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


def list_prs_to_merge(prs: list, allowed_users: list[str]) -> list:
    prs_to_merge = []
    for pr in prs:
        if decide_merge(pr, allowed_users) is True:
            prs_to_merge.append(pr)
    return prs_to_merge


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Merge PRs on clan.lol")
    # parse a list of allowed users
    parser.add_argument(
        "--allowed-users",
        nargs="+",
        help="list of users allowed to merge",
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
    allowed_users = args.allowed_users
    repos = args.repos
    dry_run = args.dry_run
    for repo in repos:
        prs = list_prs(repo)
        prs_to_merge = list_prs_to_merge(prs, allowed_users)
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
                print(
                    f"Would merge PR {pr['number']} in repo {repo} from user {pr['user']['login']}"
                )
            else:
                print("Merging PR " + str(pr["id"]))
                data = dict(
                    Do="merge",
                )
                data_encoded = json.dumps(data).encode("utf8")
                print(data)
                req = urllib.request.Request(
                    url, data=data_encoded, headers={"Content-Type": "application/json"}
                )
                urllib.request.urlopen(req)


if __name__ == "__main__":
    clan_merge()
