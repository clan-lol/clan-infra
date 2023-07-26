import pytest

import clan_merge


def test_no_args(capsys: pytest.CaptureFixture) -> None:
    # handle EsystemExit via pytest.raises
    with pytest.raises(SystemExit):
        clan_merge.clan_merge(gitea_token="")
    captured = capsys.readouterr()
    assert captured.err.startswith("usage:")


def test_decide_merge_allowed(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(clan_merge, "is_ci_green", lambda x: True)
    allowed_users = ["foo"]
    bot_name = "some-bot-name"
    pr = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=True,
        state="open",
        assignees=[dict(login=bot_name)],
    )
    assert clan_merge.decide_merge(pr, allowed_users, bot_name=bot_name) is True


def test_decide_merge_not_allowed(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(clan_merge, "is_ci_green", lambda x: True)
    allowed_users = ["foo"]
    pr1 = dict(
        id=1,
        user=dict(login="bar"),
        title="Some PR Title",
        mergeable=True,
        state="open",
        assignees=[dict(login="foo")],
    )
    pr2 = dict(
        id=1,
        user=dict(login="foo"),
        title="WIP: xyz",
        mergeable=True,
        state="open",
        assignees=[dict(login="foo")],
    )
    pr3 = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=False,
        state="open",
        assignees=[dict(login="foo")],
    )
    pr4 = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=True,
        state="closed",
        assignees=[dict(login="foo")],
    )
    pr5 = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=True,
        state="open",
        assignees=[dict(login="clan-bot")],
    )
    assert clan_merge.decide_merge(pr1, allowed_users, bot_name="some-bot") is False
    assert clan_merge.decide_merge(pr2, allowed_users, bot_name="some-bot") is False
    assert clan_merge.decide_merge(pr3, allowed_users, bot_name="some-bot") is False
    assert clan_merge.decide_merge(pr4, allowed_users, bot_name="some-bot") is False
    assert clan_merge.decide_merge(pr5, allowed_users, bot_name="some-bot") is False


def test_list_prs_to_merge(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(clan_merge, "is_ci_green", lambda x: True)
    bot_name = "some-bot-name"
    prs = [
        dict(
            id=1,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="foo"),
            state="open",
            title="PR 1",
            mergeable=True,
            assignees=[dict(login=bot_name)],
        ),
        dict(
            id=2,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="foo"),
            state="open",
            title="WIP: xyz",
            mergeable=True,
            assignees=[dict(login=bot_name)],
        ),
        dict(
            id=3,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="bar"),
            state="open",
            title="PR 2",
            mergeable=True,
            assignees=[dict(login=bot_name)],
        ),
    ]
    assert clan_merge.list_prs_to_merge(prs, ["foo"], bot_name=bot_name) == [prs[0]]
