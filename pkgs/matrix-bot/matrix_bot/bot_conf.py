from dataclasses import dataclass
from pathlib import Path


@dataclass
class BotConfig:
    data_dir: Path
    disable_pr_bot: bool
    disable_changelog_bot: bool
