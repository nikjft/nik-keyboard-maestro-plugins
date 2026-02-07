# Keyboard Maestro Gemini Plugins

This repository contains Keyboard Maestro plugins that leverage the power of Google's Gemini API for text processing and image generation.

## Plugins

### 1. **Google Gemini** (Text Processing)
Use the Gemini API to process text prompts directly within your macros.
-   **Models Support**: `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-3-flash-preview`, `gemini-3-pro-preview`.
-   **Capabilities**: Text generation, code writing, summarization, and more.
-   **Inputs**: Acceptance of Keyboard Maestro variables in prompts.

### 2. **Nano Banana** (Image Generation)
Generate images from text descriptions using Google's Imagen models.
-   **Models Support**: `imagen-3.0-generate-001`, `imagen-4.0-fast`, `imagen-4.0-generate`, `imagen-4.0-ultra`.
-   **Features**: Selectable aspect ratios (1:1, 16:9, 4:3, etc.).

## Prerequisites

You need a Google Gemini API key to use these plugins.
👉 **[Get your API Key from Google AI Studio](https://aistudio.google.com/api-keys)**

## Installation

1.  **Download**: Clone this repository or download the desired plugin folder.
2.  **Install**:
    *   Navigate to the plugin folder (e.g., `Gemini` or `Nano Banana`).
    *   Double-click the `.zip` file (if applicable) or the `Keyboard Maestro Action.plist` file.
    *   Keyboard Maestro should open and ask to install the plugin.

For more detailed instructions on installing custom plugins, please refer to the official documentation:
[Keyboard Maestro Wiki: Plug In Actions](https://wiki.keyboardmaestro.com/Plug_In_Actions)

## Configuration

For best practices and security, it is recommended to store your API Key in a Keyboard Maestro Variable (e.g., `%Variable%GeminiAPIKey%`) rather than hardcoding it into every action standard.

## Disclaimer

**"Vibe Coding" Edition**
This software is provided "as is", without warranty of any kind. It is based on partial vibe coding and may contain bugs or unexpected behaviors. Use at your own risk.

**Not Affiliated**
This project is an independent set of plugins and is not affiliated with, endorsed by, or connected to Stairways Software Pty Ltd (creators of Keyboard Maestro). Keyboard Maestro® is a registered trademark of Stairways Software Pty Ltd.

## License

MIT License

Copyright (c) 2024 Nik

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
