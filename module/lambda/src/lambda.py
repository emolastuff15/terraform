import json
import urllib.parse
import boto3

# 创建 S3 client（放在 handler 外面，复用连接）
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # 1. 从 S3 事件中提取基础信息
    record = event['Records'][0]
    bucket = record['s3']['bucket']['name']
    s3_info = record['s3']['object']

    # 2. 解码 key
    key = urllib.parse.unquote_plus(record['s3']['object']['key'])
    event_time = record['eventTime']



    # 4. 提取所需字段
    size_bytes = s3_info.get('size', 0)
    etag = s3_info.get('eTag', '').strip('"')
    extension = key.split('.')[-1] if '.' in key else ''
    sequencer = record['s3']['object']['sequencer']

    # 5. 组装 JSON 文档
    document = {
        "decoded_key": key,
        "size_bytes": size_bytes,
        "etag": etag,
        "extension": extension,
        "event_time": event_time
    }

    output = f"metadata/{bucket}/{key}/{sequencer}.json"

    s3_client.put_object(
        Bucket=bucket,
        Key=output,
        Body=json.dumps(document),
        ContentType="application/json"
    )

    return {
        'statusCode': 200,
        'body': json.dumps(document),
        'output': output
    }