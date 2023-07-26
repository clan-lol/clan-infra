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
    pr = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=True,
        state="open",
    )
    assert clan_merge.decide_merge(pr, allowed_users) is True


def test_decide_merge_not_allowed(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(clan_merge, "is_ci_green", lambda x: True)
    allowed_users = ["foo"]
    pr1 = dict(
        id=1,
        user=dict(login="bar"),
        title="Some PR Title",
        mergeable=True,
        state="open",
    )
    pr2 = dict(
        id=1,
        user=dict(login="foo"),
        title="WIP: xyz",
        mergeable=True,
        state="open",
    )
    pr3 = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=False,
        state="open",
    )
    pr4 = dict(
        id=1,
        user=dict(login="foo"),
        title="Some PR Title",
        mergeable=True,
        state="closed",
    )
    assert clan_merge.decide_merge(pr1, allowed_users) is False
    assert clan_merge.decide_merge(pr2, allowed_users) is False
    assert clan_merge.decide_merge(pr3, allowed_users) is False
    assert clan_merge.decide_merge(pr4, allowed_users) is False


def test_list_prs_to_merge(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(clan_merge, "is_ci_green", lambda x: True)
    prs = [
        dict(
            id=1,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="foo"),
            state="open",
            title="PR 1",
            mergeable=True,
        ),
        dict(
            id=2,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="foo"),
            state="open",
            title="WIP: xyz",
            mergeable=True,
        ),
        dict(
            id=3,
            base=dict(repo=dict(name="repo1")),
            head=dict(sha="1234567890"),
            user=dict(login="bar"),
            state="open",
            title="PR 2",
            mergeable=True,
        ),
    ]
    assert clan_merge.list_prs_to_merge(prs, ["foo"]) == [prs[0]]
