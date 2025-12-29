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



#Costumers
class Customers(CSVModel):
    customer_id: str
    customer_unique_id: str
    customer_zip_code_prefix: int
    customer_city: str 
    customer_state: str

#GeoLocation
class GeoLocation(CSVModel):
    geolocation_zip_code_prefix: int
    geolocation_lat: float
    geolocation_lng: float
    geolocation_city: str 
    geolocation_state: str

#OrderItems
class OrderItems(CSVModel):
    order_id: str
    order_item_id: int
    product_id: str
    seller_id: str 
    shipping_limit_date: datetime
    price: float
    freight_value: float

#OrderPayments
class OrderPayments(CSVModel):
    order_id: str
    payment_sequential: int
    payment_type: str
    payment_installments: int 
    payment_value: float

#OrderReviews
class OrderReviews(CSVModel):
    review_id: str
    order_id: str
    review_score: int
    review_comment_title: str | None
    review_comment_message: str | None
    review_creation_date: date 
    review_answer_timestamp: datetime

class Orders(CSVModel):
    order_id: str
    customer_id: str
    order_status: str
    order_purchase_timestamp: datetime
    order_approved_at: datetime
    order_delivered_carrier_date: datetime | None
    order_delivered_customer_date: datetime | None
    order_estimated_delivery_date: date


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

class Sellers(CSVModel):
    seller_id: str
    seller_zip_code_prefix: int
    seller_city: str
    seller_state: str

class ProductCategory(CSVModel):
    product_category_name: str
    product_category_name_english: str



