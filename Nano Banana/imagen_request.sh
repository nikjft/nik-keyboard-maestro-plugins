#!/bin/bash

# V4 - Gemini Only (No Imagen)
# Supports: gemini-2.5-flash-image, gemini-3-pro-image-preview-2K, gemini-3-pro-image-preview-4K

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
import json, sys

model = sys.argv[1]
prompt = sys.argv[2]
aspect_ratio = sys.argv[3]
api_key = sys.argv[4]

# Defaults
image_size = None
model_check = model.lower()

# Process Resolution Suffixes for Gemini 3
if model_check.endswith('-2k'):
    model = model[:-3] # Remove last 3 chars
    image_size = '2K'
elif model_check.endswith('-4k'):
    model = model[:-3] # Remove last 3 chars
    image_size = '4K'
# For Gemini 2.5 (or others without suffix), image_size remains None

# Endpoint
url = f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent'

# Payload Structure
payload = {
    'contents': [
        {
            'parts': [
                {'text': prompt}
            ]
        }
    ]
}

# Generation Config
generation_config = {
    'responseModalities': ['IMAGE']
}
image_config = {}

# Add Aspect Ratio if provided
if aspect_ratio:
    image_config['aspectRatio'] = aspect_ratio

# Add Image Size if detected (2K or 4K only)
if image_size:
    image_config['imageSize'] = image_size

# If any image config exists, add to generationConfig
if image_config:
    generation_config['imageConfig'] = image_config
    # Add to payload
    payload['generationConfig'] = generation_config

# Write endpoint to a file
with open('/tmp/imagen_endpoint.txt', 'w') as f:
    f.write(url)
    
# Write payload
print(json.dumps(payload))
" "$MODEL" "$PROMPT" "$ASPECT_RATIO" "$API_KEY" > /tmp/imagen_payload.json

# Read the endpoint URL
ENDPOINT_URL=$(cat /tmp/imagen_endpoint.txt)
JSON_DATA=$(cat /tmp/imagen_payload.json)

# 3. Make the Request
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

    # Check for Gemini API errors
    if 'error' in data:
        print(f\"API Error: {data['error']['message']}\")
        sys.exit(1)

    # ---------------------------------------------------------
    # HANDLE GEMINI RESPONSE
    # ---------------------------------------------------------
    # candidates[0].content.parts[0].inlineData.data
    
    b64_data = None
    
    if 'candidates' in data:
        candidates = data.get('candidates', [])
        if candidates:
            parts = candidates[0].get('content', {}).get('parts', [])
            for part in parts:
                if 'inlineData' in part:
                    b64_data = part['inlineData']['data']
                    break
    
    if not b64_data:
        print(f\"Error: No image data found. Check /tmp/imagen_raw.json.\")
        # Print a snippet for debugging
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
    cat "$RESULT_PATH"
else
    # FAILURE: Print the error message text.
    echo "$RESULT_PATH"
fi
