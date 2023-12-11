# text-gen

## Introduction
A container for using [text-generation-webui](https://github.com/oobabooga/text-generation-webui) with GPU on an OpenShift cluster.

To get set up an autoscaling GPU machinset on your OpenShift cluster in AWS quickly, see:
https://github.com/redhat-na-ssa/datasci-keras-gpt2-nlp

## Usage

### Install
- Create a namespace to work in
  - `oc new-project text-gen`
- Create a secret with credentials to protect the endpoint
  - `oc create secret generic text-gen-auth --from-literal GRADIO_USERNAME=foo --from-literal GRADIO_PASSWORD=bar --from-literal API_KEY=baz`
- Launch the app
  - `oc new-app quay.io/jmontleon/text-gen:latest`
- Set resources to launch the container on the proper node
  - `oc set resources deploy/text-gen --limits=nvidia.com/gpu=1`
- Set the required env vars from the secret
  - `oc set env deploy/text-gen --from=secret/text-gen-auth`
- Add storage for downloaded models
  - `oc set volumes deploy/text-gen --add -t pvc -m /text-generation-webui/models --claim-class gp3-csi --claim-name models --claim-size 100Gi --name models`
- Expose the services
  - `oc create route edge --service=text-gen --insecure-policy=Redirect --port 7860`
  - `oc create route edge text-gen-api --service=text-gen --insecure-policy=Redirect --port 5000`

### Prepare to use a model
- Log into the UI.
- Find some models to load, maybe on https://huggingface.co/
- Visit the models tab, download a model, like `codellama/CodeLlama-13b-hf`.
- Select a model to load
- Set options like `load_in_4bit` and `use_double_quant` to your liking. 
- Click load and wait patiently for it to finish
- Visit the parameters page and adjust the values such as temperature, etc.

### API
This is an example using curl. Be sure to replace the Bearer Token with your API Key.
```
curl -k https://text-gen-api-text-gen.apps.cluster.example.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $REPLACE-WITH-YOUR-API-KEY" \
    -d '{
      "messages": [
        {
          "role": "user",
          "content": "Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n### Instruction: Write a python program that prints hello world\n\n### Response:"
        }
      ],
      "mode": "instruct",
      "instruction_template": "Alpaca",
      "stream": true
    }'
```

This is an example using python. Be sure to replace the Bearer Token with your API Key. If you save this as `api-example.py`, running `python -u api-example.py` to stream responses to your prompts.
```
import requests
import sseclient # dnf install python3-sseclient-py / pip install sseclient-py
import json

url = "https://text-gen-api-text-gen.apps.cluster.example.com/v1/chat/completions"

headers = {
    "Authorization": "Bearer $REPLACE-WITH-YOUR-API-KEY",
    "Content-Type": "application/json"
}

history = []

while True:
    user_message = input("> ")
    history.append({"role": "user", "content": user_message})
    data = {
        "mode": "instruct",
        "stream": True,
        "messages": history
    }

    stream_response = requests.post(url, headers=headers, json=data, verify=False, stream=True)
    client = sseclient.SSEClient(stream_response)

    assistant_message = ''
    for event in client.events():
        payload = json.loads(event.data)
        chunk = payload['choices'][0]['message']['content']
        assistant_message += chunk
        print(chunk, end='')

    print()
    history.append({"role": "assistant", "content": assistant_message})
```

To use langchain

```
from langchain.chat_models import ChatOpenAI

llm = ChatOpenAI(openai_api_key="$REPLACE-WITH-YOUR-API-KEY", openai_api_base="https://text-gen-api-text-gen.apps.cluster.example.com.com/v1", streaming=True)
```

## Known Issues
- ~~There are no spaces between words in the outputs~~
  - ~~https://github.com/oobabooga/text-generation-webui/issues/4834~~
  - ~~Using the most recent snapshot seems to resolve this for now.~~
- Only the Transformers loader works so far
- Should not need to set `LD_LIBRARY_PATH`
  - https://github.com/oobabooga/text-generation-webui/issues/4517
  - https://github.com/oobabooga/text-generation-webui/issues/4195
- Should not need to pin Torch version and install then uninstall flash-attn
  - https://github.com/oobabooga/text-generation-webui/issues/4182
- Unsure if we need to be pinning bitsandbytes
- This image is impossibly monstrously large
