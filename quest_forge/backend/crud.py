
from sqlalchemy.orm import Session
from backend import models, schemas
from datetime import date
import random # Import random for quest assignment

def get_user_status(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None

    # Calculate exp to next level (example: 100, 150, 225, ...)
    exp_to_next_level = 100 * (1.5 ** (user.level - 1))

    # Get today's completed quests from daily_assigned_quests
    today = date.today()
    completed_quests_today = db.query(models.Quest).join(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == user_id,
        models.daily_assigned_quests.c.assignment_date == today,
        models.daily_assigned_quests.c.is_completed == True
    ).all()

    return schemas.UserStatus(
        id=user.id,
        level=user.level,
        exp=user.exp,
        exp_to_next_level=int(exp_to_next_level),
        total_exp=user.total_exp,
        completed_quests_count=len(completed_quests_today),
        completed_quests=completed_quests_today
    )

def create_user(db: Session):
    db_user = models.User()
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_quests(db: Session, user_id: int = 1, skip: int = 0, limit: int = 100):
    # Return quests assigned for today that are not yet completed
    today = date.today()
    assigned_quests_query = db.query(models.Quest).join(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == user_id,
        models.daily_assigned_quests.c.assignment_date == today,
        models.daily_assigned_quests.c.is_completed == False
    )
    return assigned_quests_query.offset(skip).limit(limit).all()

def assign_daily_quests(db: Session, user_id: int = 1):
    today = date.today()

    # Check if quests are already assigned for today
    existing_assignments = db.query(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == user_id,
        models.daily_assigned_quests.c.assignment_date == today
    ).first()

    if existing_assignments:
        return {"message": "Quests already assigned for today."}

    # Get all DAILY quests
    daily_quests = db.query(models.Quest).filter(models.Quest.quest_type == models.QuestType.DAILY).all()

    # Get all RANDOM quests
    random_quests_pool = db.query(models.Quest).filter(models.Quest.quest_type == models.QuestType.RANDOM).all()

    # Randomly select a few (e.g., 3-5) random quests
    num_random_quests = random.randint(3, 5)
    selected_random_quests = random.sample(random_quests_pool, min(num_random_quests, len(random_quests_pool)))

    quests_to_assign = daily_quests + selected_random_quests

    # Assign quests
    for quest in quests_to_assign:
        insert_stmt = models.daily_assigned_quests.insert().values(
            user_id=user_id,
            quest_id=quest.id,
            assignment_date=today,
            is_completed=False
        )
        db.execute(insert_stmt)
    db.commit()
    return {"message": f"Assigned {len(quests_to_assign)} quests for today."}


def create_quest(db: Session, quest: schemas.QuestCreate):
    db_quest = models.Quest(**quest.dict())
    db.add(db_quest)
    db.commit()
    db.refresh(db_quest)
    return db_quest

def complete_quest(db: Session, user_id: int, quest_id: int):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    quest = db.query(models.Quest).filter(models.Quest.id == quest_id).first()

    if not user or not quest:
        return None

    today = date.today()

    # Check if quest is assigned for today and not yet completed
    assigned_quest_entry = db.query(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == user_id,
        models.daily_assigned_quests.c.quest_id == quest_id,
        models.daily_assigned_quests.c.assignment_date == today
    ).first()

    if not assigned_quest_entry:
        return {"message": "Quest not assigned for today or already completed."}

    if assigned_quest_entry.is_completed:
        return {"message": "Quest already completed today."}

    # Update assignment status
    update_stmt = models.daily_assigned_quests.update().where(
        (models.daily_assigned_quests.c.user_id == user_id) &
        (models.daily_assigned_quests.c.quest_id == quest_id) &
        (models.daily_assigned_quests.c.assignment_date == today)
    ).values(is_completed=True)
    db.execute(update_stmt)

    user.exp += quest.exp_value
    user.total_exp += quest.exp_value

    # Level up logic
    exp_to_next_level = 100 * (1.5 ** (user.level - 1))
    while user.exp >= exp_to_next_level:
        user.level += 1
        user.exp -= int(exp_to_next_level)
        exp_to_next_level = 100 * (1.5 ** (user.level - 1))

    # Record completion in user_quests history
    insert_stmt = models.user_quests.insert().values(
        user_id=user_id,
        quest_id=quest_id,
        completion_date=today
    )
    db.execute(insert_stmt)

    db.commit()
    db.refresh(user)
    return {"message": f"Quest completed! +{quest.exp_value} EXP"}

def delete_quest(db: Session, quest_id: int):
    quest = db.query(models.Quest).filter(models.Quest.id == quest_id).first()
    if quest:
        db.delete(quest)
        db.commit()
        return True
    return False

def get_all_quests(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Quest).order_by(models.Quest.id.desc()).offset(skip).limit(limit).all()

def get_user_completion_history(db: Session, user_id: int):
    history = db.query(models.user_quests).filter(models.user_quests.c.user_id == user_id).order_by(models.user_quests.c.completion_date.desc()).all()

    # Manually construct the response to match the QuestCompletion schema
    history_with_quests = []
    for record in history:
        quest = db.query(models.Quest).filter(models.Quest.id == record.quest_id).first()
        history_with_quests.append(schemas.QuestCompletion(
            completion_date=record.completion_date,
            quest=schemas.Quest.from_orm(quest)
        ))
    return history_with_quests

def assign_quest_manually(db: Session, user_id: int, quest_id: int):
    today = date.today()

    # Check if the quest is already assigned for today
    existing_assignment = db.query(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == user_id,
        models.daily_assigned_quests.c.quest_id == quest_id,
        models.daily_assigned_quests.c.assignment_date == today
    ).first()

    if existing_assignment:
        return {"message": "Quest is already assigned for today."}

    # Assign the quest
    insert_stmt = models.daily_assigned_quests.insert().values(
        user_id=user_id,
        quest_id=quest_id,
        assignment_date=today,
        is_completed=False
    )
    db.execute(insert_stmt)
    db.commit()
    return {"message": "Quest assigned to today's tasks."}
