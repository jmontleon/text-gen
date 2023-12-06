# text-gen

## Introduction
A container for using [text-generation-webui](https://github.com/oobabooga/text-generation-webui) with GPU on an OpenShift cluster.

To get set up an autoscaling GPU machinset on your OpenShift cluster in AWS quickly, see:
https://github.com/redhat-na-ssa/datasci-keras-gpt2-nlp

## Usage
- Create a namespace to work in
  - `oc new-project text-gen`
- Create a secret with credentials to protect the endpoint
  - `oc create secret generic gradio-auth --from-literal GRADIO_USERNAME=foo --from-literal GRADIO_PASSWORD=bar` 
- Launch the app 
  - `oc new-app quay.io/jmontleon/text-gen:latest`
- Set resources to launch the container on the proper node
  - `oc set resources deploy/text-gen --limits=nvidia.com/gpu=1`
- Set the required env vars from the secret
  - `oc set env deploy/text-gen --from=secret/gradio-auth`
- Add storage for downloaded models
  - `oc set volumes deploy/text-gen --add -t pvc -m /text-generation-webui/models --claim-class gp3-csi --claim-name models --claim-size 100Gi --name models`
- Expose the service
  - `oc create route edge --service=text-gen --insecure-policy=Redirect --port 7860`

## Known Issues
- There are no spaces between words in the outputs
  - https://github.com/oobabooga/text-generation-webui/issues/4834
- Only the Transformers loader works so far
- Should not need to set `LD_LIBRARY_PATH`
  - https://github.com/oobabooga/text-generation-webui/issues/4517
  - https://github.com/oobabooga/text-generation-webui/issues/4195
- Should not need to pin Torch version
  - https://github.com/oobabooga/text-generation-webui/issues/4182
- This image is impossibly monstrously large
