"""
Rerank endpoint для Protocol.
Использует OpenRouter/Cohere для ранжирования результатов по релевантности.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from shared.http_client import http
import os

router = APIRouter()

RERANK_URL = "https://openrouter.ai/api/v1/rerank"
DEFAULT_RERANK_MODEL = "cohere/rerank-english-v3.0"


class RerankRequest(BaseModel):
    query: str
    documents: List[str]
    model: Optional[str] = DEFAULT_RERANK_MODEL
    top_n: Optional[int] = 5


class RerankResult(BaseModel):
    index: int
    relevance_score: float
    document: str


class RerankResponse(BaseModel):
    results: List[RerankResult]


@router.post("", response_model=RerankResponse)
async def rerank_documents(body: RerankRequest):
    """
    Rerank документов по релевантности запросу.
    Комбинируется с FTS5 поиском для гибридного ранжирования.
    """
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise HTTPException(500, "OPENROUTER_API_KEY not configured")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://shtab-ai.ru",
        "X-Title": "DoctorM&Ai Protocol",
    }

    payload = {
        "model": body.model,
        "query": body.query,
        "documents": body.documents,
        "top_n": body.top_n,
    }

    resp = await http.post(RERANK_URL, json=payload, headers=headers)
    resp.raise_for_status()
    data = resp.json()

    return RerankResponse(results=data.get("results", []))