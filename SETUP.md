# OpenCode + Local Models Setup Guide

## Prerequisites Configuration

### 1. Configure OpenCode with Cloud Providers

Run these commands in OpenCode (`/connect`):

#### GitHub Copilot
1. Run `/connect` 
2. Search for "GitHub Copilot"
3. Navigate to github.com/login/device and enter the code
4. Ensure you have Copilot Pro+ subscription for advanced models

#### OpenAI  
1. Run `/connect`
2. Search for "OpenAI"
3. Select "ChatGPT Plus/Pro" for OAuth or "Manually enter API Key"
4. Use your ChatGPT Plus/Pro subscription

#### Google Gemini (Vertex AI)
1. Set environment variables:
   ```bash
   export GOOGLE_CLOUD_PROJECT=your-project-id
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   # OR authenticate with: gcloud auth application-default login
   ```
2. Run `/connect`
3. Search for "Google Vertex AI"

### 2. Verify Configuration
Run `/models` to see all available models from your configured providers.

## Next Steps: Local Model Infrastructure

After configuring cloud providers, we'll set up:
- Docker Compose for GPU-accelerated model serving
- Ansible for system configuration
- Ollama/Llama.cpp for local model execution

## Testing Configuration
Test each provider:
```bash
# Test OpenAI
opencode run "Test response from OpenAI"

# Test GitHub Copilot  
opencode run "Test response from GitHub Copilot"

# Test Google Vertex AI
opencode run "Test response from Google Vertex AI"
```