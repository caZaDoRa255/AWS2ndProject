# app/upload/router.py

from fastapi import APIRouter, Query, HTTPException
from app.presigned.service import generate_upload_url

router = APIRouter(prefix="/upload", tags=["Upload"])

@router.get("/presigned-url")
def get_presigned_upload_url(filename: str = Query(..., description="업로드할 파일 이름")):
    url = generate_upload_url(filename)
    if not url:
        raise HTTPException(status_code=500, detail="Presigned URL 생성 실패")
    return {"upload_url": url}
