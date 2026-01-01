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


#GeoLocation
class GeoLocation(CSVModel):
    geolocation_zip_code_prefix: int
    geolocation_lat: float
    geolocation_lng: float
    geolocation_city: str 
    geolocation_state: str
