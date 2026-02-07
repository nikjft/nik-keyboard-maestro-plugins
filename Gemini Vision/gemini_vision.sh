#!/bin/bash

# 1. Capture KM Parameters
MODEL="$KMPARAM_Model"
API_KEY="$KMPARAM_API_Key"
PROMPT="$KMPARAM_Prompt"
IMAGE_SOURCE="$KMPARAM_Image_Source"

# Safety Check: API Key
if [ -z "$API_KEY" ]; then
    echo "Error: API Key is missing."
    exit 1
fi

# Define the working temp file
TEMP_IMG="/tmp/km_vision_input.jpg"
rm -f "$TEMP_IMG"

# 2. Resolve Image Source
# Logic: If the parameter is a valid file on disk, use it.
# Otherwise (if it's empty, or a KM placeholder like "[Image...]"), default to System Clipboard.
if [ -f "$IMAGE_SOURCE" ]; then
    cp "$IMAGE_SOURCE" "$TEMP_IMG"
else
    # Use AppleScript to dump clipboard to file
    osascript -e '
        try
            set theData to the clipboard as JPEG picture
            set theFile to open for access POSIX file "/tmp/km_vision_input.jpg" with write permission
            set eof of theFile to 0
            write theData to theFile
            close access theFile
        on error
            return "NO_IMAGE"
        end try
    ' > /dev/null
fi

# 3. Validate Image Data
if [ ! -f "$TEMP_IMG" ]; then
    echo "Error: No image data found. (Input was not a file, and Clipboard was empty)."
    exit 1
fi

# 4. Process via Python
python3 -c "
import sys, json, base64, urllib.request, os

api_key = '$API_KEY'
model = '$MODEL'
prompt_text = sys.argv[1]
image_path = '/tmp/km_vision_input.jpg'

try:
    # Read and Encode Image
    with open(image_path, 'rb') as image_file:
        b64_image = base64.b64encode(image_file.read()).decode('utf-8')

    # Construct JSON Payload
    data = {
        'contents': [{
            'parts': [
                {'text': prompt_text},
                {
                    'inline_data': {
                        'mime_type': 'image/jpeg',
                        'data': b64_image
                    }
                }
            ]
        }]
    }
    
    # Prepare Request
    url = f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}'
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    
    # Send Request
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        
        # Parse Response
        try:
            print(result['candidates'][0]['content']['parts'][0]['text'])
        except (KeyError, IndexError):
            print(f'Error Parsing Response: {json.dumps(result)}')

except urllib.error.HTTPError as e:
    print(f'API Error {e.code}: {e.read().decode(\"utf-8\")}')
except Exception as e:
    print(f'Script Error: {str(e)}')
" "$PROMPT"