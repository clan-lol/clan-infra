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


def get_api_key() -> str:
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
    max_response_tokens: int = 4096,
) -> list[bytes]:
    def split_message(content: str, max_tokens: int) -> list[str]:
        # Split the content into chunks of max_tokens
        content_tokens = encoder.encode(content)
        chunks = []
        for i in range(0, len(content_tokens), max_tokens):
            chunk = content_tokens[i : i + max_tokens]
            chunks.append(encoder.decode(chunk))
            log.debug(f"Chunk {i / max_tokens}: {len(chunk)} tokens")
        return chunks

    encoder = tiktoken.encoding_for_model(model)
    max_message_tokens = 127_000 - max_response_tokens

    # Split user_prompt into multiple user messages if it exceeds the max_message_tokens
    user_messages = []
    for message_chunk in split_message(user_prompt, max_message_tokens):
        if len(message_chunk) == 0:
            raise Exception("Empty message chunk")
        user_messages.append({"role": "user", "content": message_chunk})

    ## count number of tokens for every user message
    count_tokens: int = 0
    for i, message in enumerate(user_messages):
        count_tokens = len(encoder.encode(message["content"]))
        log.debug(f"Number of tokens in the user messages: {count_tokens}")
        if count_tokens > max_message_tokens:
            raise Exception(f"Too many tokens in the user message[{i}] {count_tokens}")

    batch_jobs: list[bytes] = []
    for message in user_messages:
        summary_request: dict[str, Any] = {
            "custom_id": "request-1",
            "method": "POST",
            "url": "/v1/chat/completions",
            "body": {
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    message,
                ],
                "max_tokens": max_response_tokens,
            },
        }

        dumped = json.dumps(summary_request)
        batch_jobs.append(dumped.encode("utf-8"))

    return batch_jobs


async def upload_and_process_files(
    *,
    session: aiohttp.ClientSession,
    jsonl_files: list[bytes],
    api_key: str | None = None,
    completion_window: str = "24h",
) -> list[dict[str, Any]]:
    """
    Upload multiple JSONL files to OpenAI's Batch API and process them asynchronously.
    """
    if api_key is None:
        api_key = get_api_key()
    headers = {
        "Authorization": f"Bearer {api_key}",
    }

    log.debug(
        f"Uploading {len(jsonl_files)} files to OpenAI, completion window: {completion_window}"
    )

    async def upload_file(jsonl_data: bytes) -> str:
        upload_url = "https://api.openai.com/v1/files"

        data = aiohttp.FormData()
        data.add_field(
            "file",
            jsonl_data,
            filename="changelog.jsonl",
            content_type="application/jsonl",
        )
        data.add_field("purpose", "batch")

        async with session.post(upload_url, headers=headers, data=data) as response:
            if response.status != 200:
                raise Exception(
                    f"File upload failed with status code {response.status}"
                )
            upload_response = await response.json()
            file_id = upload_response.get("id")

        if not file_id:
            raise Exception("File ID not returned from upload")

        return file_id

    async def create_batch(file_id: str) -> str:
        batch_url = "https://api.openai.com/v1/batches"
        batch_data = {
            "input_file_id": file_id,
            "endpoint": "/v1/chat/completions",
            "completion_window": f"{completion_window}",
        }

        async with session.post(
            batch_url, headers=headers, json=batch_data
        ) as response:
            if response.status != 200:
                raise Exception(
                    f"Batch creation failed with status code {response.status}"
                )
            batch_response = await response.json()
            batch_id = batch_response.get("id")

        if not batch_id:
            raise Exception("Batch ID not returned from creation")

        return batch_id

    async def check_batch_status(batch_id: str) -> str:
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
                    if status != "completed":
                        raise Exception(
                            f"Batch processing failed with status: {status}"
                        )
                    return status_response.get("output_file_id")
            await asyncio.sleep(10)

    async def retrieve_results(output_file_id: str) -> list[dict[str, Any]]:
        output_url = f"https://api.openai.com/v1/files/{output_file_id}/content"
        async with session.get(output_url, headers=headers) as response:
            if response.status != 200:
                raise Exception(
                    f"Failed to retrieve batch results with status code {response.status} reason {response.reason}"
                )
            content = await response.text()
        results = [json.loads(line) for line in content.splitlines()]
        return results

    file_ids = await asyncio.gather(
        *[upload_file(jsonl_data) for jsonl_data in jsonl_files]
    )
    batch_ids = await asyncio.gather(*[create_batch(file_id) for file_id in file_ids])
    output_file_ids = await asyncio.gather(
        *[check_batch_status(batch_id) for batch_id in batch_ids]
    )
    all_results = await asyncio.gather(
        *[retrieve_results(output_file_id) for output_file_id in output_file_ids]
    )

    # Flatten the list of results
    combined_results = [item for sublist in all_results for item in sublist]

    return combined_results
