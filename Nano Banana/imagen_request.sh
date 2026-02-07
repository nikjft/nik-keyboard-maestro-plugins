#!/bin/bash

# V3 - Gemini/Imagen User-Aligned Code

# 1. Capture KM Parameters
MODEL="$KMPARAM_Model"
API_KEY="$KMPARAM_API_Key"
PROMPT="$KMPARAM_Prompt"
ASPECT_RATIO="$KMPARAM_Aspect_Ratio"

# Safety Check
if [ -z "$API_KEY" ]; then
    echo "Error: API Key is missing."
    exit 1
fi

# 2. Prepare JSON Payload & Endpoint via Python
python3 -c "
import json, sys, os

model = sys.argv[1]
prompt = sys.argv[2]
aspect_ratio = sys.argv[3]
api_key = sys.argv[4]

# Check if model string contains 'gemini' (case-insensitive)
if 'gemini' in model.lower():
    # GEMINI API (generateContent)
    # Using the user's preferred format with x-goog-api-key header in curl (processed outside)
    url = f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent'
    
    # User's provided working payload structure for Gemini Nano Banana
    payload = {
        'contents': [
            {
                'parts': [
                    {'text': prompt}
                ]
            }
        ]
    }
    
    # Write endpoint to a file
    with open('/tmp/imagen_endpoint.txt', 'w') as f:
        f.write(url)
        
    # Write payload
    print(json.dumps(payload))
    
    # Marker for shell to know it is gemini
    with open('/tmp/imagen_mode.txt', 'w') as f:
        f.write('gemini')

else:
    # IMAGEN API (predict)
    url = f'https://generativelanguage.googleapis.com/v1beta/models/{model}:predict'
    
    payload = {
        'instances': [
            {'prompt': prompt}
        ],
        'parameters': {
            'sampleCount': 1,
            'aspectRatio': aspect_ratio
        }
    }
    
    with open('/tmp/imagen_endpoint.txt', 'w') as f:
        f.write(url)

    print(json.dumps(payload))
    
    with open('/tmp/imagen_mode.txt', 'w') as f:
        f.write('imagen')

" "$MODEL" "$PROMPT" "$ASPECT_RATIO" "$API_KEY" > /tmp/imagen_payload.json

# Read the endpoint URL and Mode
ENDPOINT_URL=$(cat /tmp/imagen_endpoint.txt)
MODE=$(cat /tmp/imagen_mode.txt)
JSON_DATA=$(cat /tmp/imagen_payload.json)

# 3. Make the Request & Save Raw JSON to File
# We use the header method for API key as preferred by the user's example
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: $API_KEY" \
  "$ENDPOINT_URL" \
  -d "$JSON_DATA" > /tmp/imagen_raw.json

# 4. Process Response (Decode Base64 & Save Image to File)
python3 -c "
import sys, json, base64

try:
    # Read the raw JSON file
    with open('/tmp/imagen_raw.json', 'r') as f:
        data = json.load(f)

    # Check for API errors
    if 'error' in data:
        print(f\"API Error: {data['error']['message']}\")
        sys.exit(1)

    # ---------------------------------------------------------
    # HANDLE RESPONSE
    # ---------------------------------------------------------
    
    b64_data = None
    
    # CHECK: Gemini format
    # candidates[0].content.parts[0].inlineData.data
    if 'candidates' in data:
        candidates = data.get('candidates', [])
        if candidates:
            parts = candidates[0].get('content', {}).get('parts', [])
            for part in parts:
                if 'inlineData' in part:
                    b64_data = part['inlineData']['data']
                    break
    
    # CHECK: Imagen format
    # predictions[0].bytesBase64Encoded (or just string)
    if not b64_data and 'predictions' in data:
        predictions = data.get('predictions', [])
        if predictions:
            prediction = predictions[0]
            if isinstance(prediction, dict) and 'bytesBase64Encoded' in prediction:
                b64_data = prediction['bytesBase64Encoded']
            elif isinstance(prediction, str):
                b64_data = prediction

    if not b64_data:
        print(f\"Error: No image data found in response. Check /tmp/imagen_raw.json for details.\")
        print(f\"JSON Preview: {str(data)[:200]}...\")
        sys.exit(1)

    # Decode and Save to temp image file
    file_path = '/tmp/google_imagen_result.png'
    with open(file_path, 'wb') as f:
        f.write(base64.b64decode(b64_data))
    
    # Print the success path
    print(file_path)

except Exception as e:
    print(f\"Processing Error: {str(e)}\")
    sys.exit(1)
" > /tmp/imagen_status.txt

# 5. Handle Output
RESULT_PATH=$(cat /tmp/imagen_status.txt)

# Check if the output is the file path we expect
if [[ "$RESULT_PATH" == "/tmp/google_imagen_result.png" ]]; then
    # SUCCESS: Output the binary image data to stdout.
    # KM will capture this into the Variable or Clipboard.
    cat "$RESULT_PATH"
else
    # FAILURE: Print the error message text.
    echo "$RESULT_PATH"
fi
