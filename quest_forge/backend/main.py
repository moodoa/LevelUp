
from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from backend import crud, models, schemas
from backend.database import SessionLocal, engine
from datetime import date

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Allow all origins for development purposes
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    db = SessionLocal()
    user = crud.get_user_status(db, user_id=1)
    if not user:
        crud.create_user(db)
    
    # Assign daily quests if not already assigned for today
    today = date.today()
    assigned_for_today = db.query(models.daily_assigned_quests).filter(
        models.daily_assigned_quests.c.user_id == 1,
        models.daily_assigned_quests.c.assignment_date == today
    ).first()
    if not assigned_for_today:
        crud.assign_daily_quests(db, user_id=1)

    db.close()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/user/status", response_model=schemas.UserStatus)
def read_user_status(user_id: int = 1, db: Session = Depends(get_db)):
    db_user = crud.get_user_status(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.post("/quests/{quest_id}/complete")
def complete_quest_endpoint(quest_id: int, user_id: int = 1, db: Session = Depends(get_db)):
    result = crud.complete_quest(db, user_id=user_id, quest_id=quest_id)
    if result is None:
        raise HTTPException(status_code=404, detail="User or Quest not found")
    return JSONResponse(content=result)

@app.get("/quests/", response_model=list[schemas.Quest])
def read_quests(user_id: int = 1, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    quests = crud.get_quests(db, user_id=user_id, skip=skip, limit=limit)
    return quests

@app.post("/quests/", response_model=schemas.Quest)
def create_quest(quest: schemas.QuestCreate, db: Session = Depends(get_db)):
    return crud.create_quest(db=db, quest=quest)

@app.delete("/quests/{quest_id}")
def delete_quest(quest_id: int, db: Session = Depends(get_db)):
    if not crud.delete_quest(db, quest_id):
        raise HTTPException(status_code=404, detail="Quest not found")
    return {"message": "Quest deleted successfully"}

@app.get("/quests/all", response_model=list[schemas.Quest])
def read_all_quests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    quests = crud.get_all_quests(db, skip=skip, limit=limit)
    return quests

@app.get("/user/history", response_model=list[schemas.QuestCompletion])
def read_user_history(user_id: int = 1, db: Session = Depends(get_db)):
    history = crud.get_user_completion_history(db, user_id=user_id)
    return history

@app.post("/quests/assign_today")
def assign_today_quests_endpoint(user_id: int = 1, db: Session = Depends(get_db)):
    result = crud.assign_daily_quests(db, user_id=user_id)
    return JSONResponse(content=result)

@app.post("/quests/{quest_id}/assign_manually")
def assign_quest_manually_endpoint(quest_id: int, user_id: int = 1, db: Session = Depends(get_db)):
    result = crud.assign_quest_manually(db, user_id=user_id, quest_id=quest_id)
    return JSONResponse(content=result)
