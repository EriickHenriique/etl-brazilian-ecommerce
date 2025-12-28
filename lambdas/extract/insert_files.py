import boto3
import os
import zipfile

s3 = boto3.client("s3")

def lambda_handler(event, context):
    bucket = os.environ["TARGET_BUCKET"]
    s3_prefix = os.environ.get("S3_PREFIX", "data/")

    base_dir = os.path.dirname(__file__) 
    zip_path = os.path.join(base_dir, "data.zip")

    if not os.path.exists(zip_path):
        raise FileNotFoundError(f"Arquivo não encontrado: {zip_path}.")

    uploaded = 0

    with zipfile.ZipFile(zip_path, "r") as z:
        for member in z.infolist():

            if member.is_dir():
                continue


            filename_in_zip = member.filename


            key = f"{s3_prefix}{filename_in_zip}"

            file_bytes = z.read(member)
            s3.put_object(Bucket=bucket, Key=key, Body=file_bytes)
            uploaded += 1

    return {"uploaded": uploaded, "bucket": bucket, "zip": "data.zip"}
