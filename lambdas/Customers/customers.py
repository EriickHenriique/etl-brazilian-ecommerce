import pandas as pd
from lambdas.Customers.contracts import Customers
from sqlalchemy import create_engine, Table, Column, MetaData, String, Integer
from sqlalchemy.dialects.postgresql import insert as pg_insert
from dotenv import load_dotenv
from loguru import logger
import time
import os 

load_dotenv()

PATH = 's3://orders-ecommerce/data/data/olist_customers_dataset.csv'
DB_URL = os.getenv("DB_URL")
BATCH_SIZE = 10_000
DELAY_SECONDS = 5

def read_csv(path) -> pd.DataFrame:
    logger.info('Processando Arquivos da S3')
    df = pd.read_csv(path, storage_options={'profile': 'default'})
    return df


def contracts(df: pd.DataFrame) -> list[dict]:
    logger.info('Validando Dados')
    records = df.to_dict(orient="records")
    validated = []
    for i, row in enumerate(records):
        try:
            validated.append(Customers(**row))            
        except Exception as e:
            logger.error('Erro no Pipeline')
            raise ValueError(f"Erro na linha {i}: {e}")
        
    logger.info('Dados Validados com Sucesso')       
    df = [item.model_dump() for item in validated]
    return df


def define_table():
    logger.info('Criando Tabelas')
    meta_obj = MetaData()
    table_name = 'bronze_customers'
    table = Table(
        table_name, meta_obj,
        Column("customer_id", String(100), primary_key=True),
        Column("customer_unique_id", String(100)),
        Column("customer_zip_code_prefix", Integer),
        Column("customer_city",String(50)),
        Column("customer_state",String(2))        
    )
    return table, meta_obj

def insert_values(path: str, db_url: str, batch_size: int, delay_seconds: int) -> dict:
    if not db_url:
        raise ValueError("DB_URL não foi definido (env var DB_URL).")
    
    engine = create_engine(DB_URL)
    table, meta = define_table()
    meta.create_all(engine)

    chunks = pd.read_csv(
        PATH,
        storage_options={'profile': 'default'},
        chunksize=BATCH_SIZE
    )

    total_processado = 0
    total_chunks = 0

    for i, df_chunk in enumerate(chunks, start=1):
        t0 = time.time()

        batch = contracts(df_chunk) 

        with engine.begin() as conn:
            logger.info(f"Upsert do chunk {i} | {len(batch)} registros...")

            stmt = pg_insert(table).values(batch)

            # atualiza tudo, exceto a chave (customer_id)
            stmt = stmt.on_conflict_do_update(
                index_elements=["customer_id"],
                set_={
                    "customer_unique_id": stmt.excluded.customer_unique_id,
                    "customer_zip_code_prefix": stmt.excluded.customer_zip_code_prefix,
                    "customer_city": stmt.excluded.customer_city,
                    "customer_state": stmt.excluded.customer_state,
                }
            )

            conn.execute(stmt)

        total_processado += len(batch)

        elapsed = time.time() - t0
        sleep_for = max(0, DELAY_SECONDS - elapsed) 
        logger.info(
            f"Chunk {i} concluído em {elapsed:.2f}s | Total processado: {total_processado} "
            f"| Aguardando {sleep_for:.2f}s..."
        )
        time.sleep(sleep_for)

    logger.success('Pipeline Concluído')

    return {
    "status": "ok",
    "path": path,
    "chunks": total_chunks,
    "records_processed": total_processado,
    "batch_size": batch_size,
    "delay_seconds": delay_seconds,
    }

insert_values()
