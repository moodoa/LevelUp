
from sqlalchemy import Column, Integer, String, Enum, Date, Table, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from .database import Base
import enum

class QuestType(str, enum.Enum):
    DAILY = "daily"
    RANDOM = "random"

# Association Table for User and Quest completion history
user_quests = Table('user_quests',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('quest_id', Integer, ForeignKey('quests.id'), primary_key=True),
    Column('completion_date', Date, primary_key=True)
)

# Association Table for daily assigned quests
daily_assigned_quests = Table('daily_assigned_quests',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('quest_id', Integer, ForeignKey('quests.id'), primary_key=True),
    Column('assignment_date', Date, primary_key=True),
    Column('is_completed', Boolean, default=False)
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    level = Column(Integer, default=1)
    exp = Column(Integer, default=0) # Current exp in this level
    total_exp = Column(Integer, default=0) # All time exp

    completed_quests = relationship("Quest", secondary=user_quests, back_populates="completed_by_users")
    assigned_quests = relationship("Quest", secondary=daily_assigned_quests, back_populates="assigned_to_users")

class Quest(Base):
    __tablename__ = "quests"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, index=True)
    exp_value = Column(Integer)
    quest_type = Column(Enum(QuestType))

    completed_by_users = relationship("User", secondary=user_quests, back_populates="completed_quests")
    assigned_to_users = relationship("User", secondary=daily_assigned_quests, back_populates="assigned_quests")
