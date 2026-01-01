from pydantic import BaseModel, ConfigDict, field_validator
from datetime import datetime
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



#OrderItems
class OrderItems(CSVModel):
    order_id: str
    order_item_id: int
    product_id: str
    seller_id: str 
    shipping_limit_date: datetime
    price: float
    freight_value: float
