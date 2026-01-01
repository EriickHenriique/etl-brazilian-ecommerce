from pydantic import BaseModel, ConfigDict, field_validator
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


#Products
class Products(CSVModel):
    product_id: str
    product_category_name: str | None
    product_name_lenght: int
    product_description_lenght: float
    product_photos_qty: int
    product_weight_g: float
    product_lenght_cm: float
    product_height_cm: float
    product_width_cm: float


