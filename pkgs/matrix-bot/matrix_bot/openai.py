import asyncio
import json
import logging
from os import environ
from typing import Any

import aiohttp
import tiktoken

log = logging.getLogger(__name__)

# The URL to which the request is sent
url: str = "https://api.openai.com/v1/chat/completions"


def api_key() -> str:
    openapi_key = environ.get("OPENAI_API_KEY")
    if openapi_key is not None:
        return openapi_key

    openai_key_file = environ.get("OPENAI_API_KEY_FILE", default=None)
    if openai_key_file is None:
        raise Exception("OPENAI_API_KEY_FILE environment variable is not set")
    with open(openai_key_file) as f:
        return f.read().strip()


async def create_jsonl_data(
    *,
    user_prompt: str,
    system_prompt: str,
    model: str = "gpt-4o",
    max_tokens: int = 4096,
) -> bytes:
    summary_request: dict[str, Any] = {
        "custom_id": "request-1",
        "method": "POST",
        "url": "/v1/chat/completions",
        "body": {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "max_tokens": max_tokens,
        },
    }

    dumped = json.dumps(summary_request)
    encoder = tiktoken.encoding_for_model(model)
    count_tokens: int = len(encoder.encode(dumped))
    used_tokens = max_tokens + count_tokens + 1000
    log.debug(f"Number of tokens in the JSONL data: {used_tokens}")

    if used_tokens > 128_000:
        # Cut off the excess tokens
        tokens_to_remove: int = used_tokens - 128_000
        message = summary_request["body"]["messages"][1]
        content = message["content"]

        content_tokens = encoder.encode(content)

        if len(content_tokens) > tokens_to_remove:
            # Remove the excess tokens
            encoded_content = content_tokens[:-tokens_to_remove]
            log.debug(f"Removed {tokens_to_remove} tokens from the content")
            # Decode the tokens back to string
            content = encoder.decode(encoded_content)
            summary_request["body"]["messages"][1]["content"] = content

            dumped = json.dumps(summary_request)
        else:
            raise Exception("Not enough tokens to remove")

    new_count_tokens: int = len(encoder.encode(dumped))
    if new_count_tokens > 128_000:
        raise Exception(f"Too many tokens in the JSONL data {new_count_tokens}")

    return dumped.encode("utf-8")


async def upload_and_process_file(
    *, session: aiohttp.ClientSession, jsonl_data: bytes, api_key: str = api_key()
) -> list[dict[str, Any]]:
    """
    Upload a JSONL file to OpenAI's Batch API and process it asynchronously.
    """

    upload_url = "https://api.openai.com/v1/files"
    headers = {
        "Authorization": f"Bearer {api_key}",
    }
    data = aiohttp.FormData()
    data.add_field(
        "file", jsonl_data, filename="changelog.jsonl", content_type="application/jsonl"
    )
    data.add_field("purpose", "batch")

    async with session.post(upload_url, headers=headers, data=data) as response:
        if response.status != 200:
            raise Exception(f"File upload failed with status code {response.status}")
        upload_response = await response.json()
        file_id = upload_response.get("id")

    if not file_id:
        raise Exception("File ID not returned from upload")

    # Step 2: Create a batch using the uploaded file ID
    batch_url = "https://api.openai.com/v1/batches"
    batch_data = {
        "input_file_id": file_id,
        "endpoint": "/v1/chat/completions",
        "completion_window": "24h",
    }

    async with session.post(batch_url, headers=headers, json=batch_data) as response:
        if response.status != 200:
            raise Exception(f"Batch creation failed with status code {response.status}")
        batch_response = await response.json()
        batch_id = batch_response.get("id")

    if not batch_id:
        raise Exception("Batch ID not returned from creation")

    # Step 3: Check the status of the batch until completion
    status_url = f"https://api.openai.com/v1/batches/{batch_id}"

    while True:
        async with session.get(status_url, headers=headers) as response:
            if response.status != 200:
                raise Exception(
                    f"Failed to check batch status with status code {response.status}"
                )
            status_response = await response.json()
            status = status_response.get("status")
            if status in ["completed", "failed", "expired"]:
                break
            await asyncio.sleep(10)  # Wait before checking again

    if status != "completed":
        raise Exception(f"Batch processing failed with status: {status}")

    # Step 4: Retrieve the results
    output_file_id = status_response.get("output_file_id")
    output_url = f"https://api.openai.com/v1/files/{output_file_id}/content"

    async with session.get(output_url, headers=headers) as response:
        if response.status != 200:
            raise Exception(
                f"Failed to retrieve batch results with status code {response.status} reason {response.reason}"
            )

        # Read content as text
        content = await response.text()

    # Parse the content as JSONL
    results = [json.loads(line) for line in content.splitlines()]
    return results
