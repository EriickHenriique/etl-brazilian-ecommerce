from pydantic import BaseModel, ConfigDict, field_validator
from datetime import datetime, date
from typing import Any

class CSVModel(BaseModel):
    model_config = ConfigDict (
        extra="forbid", # Identificação de Colunas Inesperadas
        str_strip_whitespace=True # Retira os espaços nas pontas
    )

    @field_validator("*", mode="before")
    @classmethod

    # Normalizador de NaN devido ao uso do Pandas para Processamento dos Dados
    def normalize_nulls(cls, v: Any):
        if v is None:
            return None
        if isinstance(v, float) and v != v:
            return None
        if isinstance(v, str) and v.strip() == "":
            return None
        return v



#OrderReviews
class OrderReviews(CSVModel):
    review_id: str
    order_id: str
    review_score: int
    review_comment_title: str | None
    review_comment_message: str | None
    review_creation_date: date 
    review_answer_timestamp: datetime

