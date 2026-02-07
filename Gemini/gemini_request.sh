#!/bin/bash

# 1. Capture KM Parameters
MODEL="$KMPARAM_Model"
API_KEY="$KMPARAM_API_Key"
PROMPT="$KMPARAM_Prompt"

# Safety Check
if [ -z "$API_KEY" ]; then
    echo "Error: API Key is missing."
    exit 1
fi

# 2. Escape the prompt safely using Python
# We use python3 to dump the string as a JSON-safe format, then remove the surrounding quotes
ESCAPED_PROMPT=$(python3 -c "import json, sys; print(json.dumps(sys.argv[1]))" "$PROMPT" | sed 's/^"//;s/"$//')

# 3. Construct the JSON Payload
JSON_DATA="{
  \"contents\": [{
    \"parts\": [{
      \"text\": \"$ESCAPED_PROMPT\"
    }]
  }]
}"

# 4. Make the Request
# We capture the output into a variable
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY" \
  -d "$JSON_DATA")

# 5. Parse the Response safely using Python
# We export the response to an environment variable so Python can read it cleanly
export RESPONSE_DATA="$RESPONSE"

python3 -c "
import sys, json, os

try:
    # Read from environment variable to avoid shell escaping issues
    raw_response = os.environ['RESPONSE_DATA']
    data = json.loads(raw_response)
    
    # Check for API-level errors
    if 'error' in data:
        print(f\"API Error: {data['error']['message']}\")
        sys.exit(1)
        
    # Extract the text
    text = data['candidates'][0]['content']['parts'][0]['text']
    print(text)

except Exception as e:
    # Fallback: print the error and the raw data for debugging
    print(f\"Parsing Error: {str(e)}\")
"