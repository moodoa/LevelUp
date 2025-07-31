
from pydantic import BaseModel, ConfigDict
from typing import Optional
from backend.models import QuestType # Keep this import for now, will be removed later
from datetime import date
import enum # Import enum module

class QuestType(str, enum.Enum):
    DAILY = "daily"
    RANDOM = "random"

class QuestBase(BaseModel):
    name: str
    description: Optional[str] = None
    exp_value: int
    quest_type: QuestType

class QuestCreate(QuestBase):
    pass

class Quest(QuestBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class UserStatus(BaseModel):
    id: int
    level: int
    exp: int
    exp_to_next_level: int
    total_exp: int
    completed_quests_count: int
    completed_quests: list[Quest]

class QuestCompletion(BaseModel):
    completion_date: date
    quest: Quest

    class Config:
        from_attributes = True
