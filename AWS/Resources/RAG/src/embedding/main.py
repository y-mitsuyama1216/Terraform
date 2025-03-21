import boto3
import requests
from bs4 import BeautifulSoup
import json
import uuid
import os
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import CharacterTextSplitter

# 環境変数から OpenSearch のエンドポイントを取得
OPENSEARCH_ENDPOINT = os.environ['OPENSEARCH_ENDPOINT'].replace("https://", "")
S3BUCKET = os.environ['S3BUCKET']
S3BUCKET_KEY = os.environ['S3BUCKET_KEY']
OPENSEARCH_INDEX = "faqs"
REGION = "ap-northeast-1"
s3_client = boto3.client("s3")

def download_pdf():
    local_path = "/tmp/"
    s3_client.download_file(S3BUCKET, S3BUCKET_KEY, local_path)
    return local_path

def embed_pdf(local_path):
    loader = PyPDFLoader(local_path)
    pages = loader.load_and_split()
    splitter = CharacterTextSplitter(chunk_size=8192)
    text = splitter.split_documents(pages)
    return text

def invoke_bedrock_embedding(client, model_id, input_text, dimensions=512, normalize=True):
    """Amazon Titan Text Embeddings V2 モデルを用いてベクトル化"""
    body = {
        "inputText": input_text,
        "dimensions": dimensions,
        "normalize": normalize
    }
    
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body)
    )

    result = json.loads(response['body'].read())
    return result['embedding']

def connect_opensearch():
    """OpenSearch Serverless への接続を作成"""
    credentials = boto3.Session().get_credentials()
    auth = AWSV4SignerAuth(credentials, REGION, "aoss")
    
    return OpenSearch(
        hosts=[{"host": OPENSEARCH_ENDPOINT, "port": 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection
    )

def index_document(opensearch_client, document_id, text, embedding):
    """OpenSearch Serverless にデータを投入"""
    document = {
        "text": text,
        "embedding": embedding
    }

    response = opensearch_client.index(
        index=OPENSEARCH_INDEX,
        body=document,
    )
    print('\nDocument added:')
    print(response)
    
    return response

def lambda_handler(event, context):
    # 対象ドキュメントのURL
    url = "https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/what-is-bedrock.html"
    
    # ドキュメントテキスト取得
    text = get_document_text(url)
    
    # チャンク化
    text_chunks = chunk_text(text, chunk_size=8192)

    # Bedrock クライアント作成
    bedrock_client = boto3.client('bedrock-runtime', region_name=REGION)

    # OpenSearch クライアント作成
    opensearch_client = connect_opensearch()

    # Bedrock でベクトル化 & OpenSearch に投入
    results = []
    model_id = "amazon.titan-embed-text-v2:0"
    
    for chunk in text_chunks:
        embedding = invoke_bedrock_embedding(bedrock_client, model_id, chunk, dimensions=512, normalize=True)
        document_id = str(uuid.uuid4())
        response = index_document(opensearch_client, document_id, chunk, embedding)
        results.append(response)

    return {
        'statusCode': 200,
        'results': results
    }
