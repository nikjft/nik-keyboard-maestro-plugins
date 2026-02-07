#!/bin/bash

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

# 2. Prepare JSON Payload via Python
JSON_DATA=$(python3 -c "
import json, sys
data = {
    'instances': [
        {'prompt': sys.argv[1]}
    ],
    'parameters': {
        'sampleCount': 1,
        'aspectRatio': sys.argv[2]
    }
}
print(json.dumps(data))
" "$PROMPT" "$ASPECT_RATIO")

# 3. Make the Request & Save Raw JSON to File
# We save to a file to avoid passing huge strings in variables
curl -s -X POST \
  -H "Content-Type: application/json" \
  "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:predict?key=$API_KEY" \
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

    # Extract Base64 string
    predictions = data.get('predictions', [])
    if not predictions:
        # Check if the response was empty or malformed
        print(f\"Error: No predictions returned. Check /tmp/imagen_raw.json for details.\")
        sys.exit(1)
        
    prediction = predictions[0]
    
    # Handle the two common formats (string or dict)
    if isinstance(prediction, dict) and 'bytesBase64Encoded' in prediction:
        b64_data = prediction['bytesBase64Encoded']
    elif isinstance(prediction, str):
        b64_data = prediction
    else:
        print(f\"Error: Unexpected prediction format.\")
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