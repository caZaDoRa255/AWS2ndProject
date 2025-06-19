from app.models.click import ClickLog
from sqlalchemy.orm import Session

def log_click(db: Session, user_id: int, content_id: int) -> ClickLog:
    click = ClickLog(user_id=user_id, content_id=content_id)
    db.add(click)
    db.commit()
    db.refresh(click)
    return click
