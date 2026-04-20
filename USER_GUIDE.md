# ⚡ JARVIS — Cyberpunk User Guide

> *Neural networks firing. Welcome to the grid.*

---

## 🌐 What is JARVIS?

JARVIS is your **encrypted AI command center** — a private, secure interface to interact with cutting-edge language models. No cloud. No data breaches. Just you, the models, and bulletproof encryption.

**The Stack:**
- 🤖 **Open WebUI** — beautiful chat interface for AI conversations
- 🧠 **Ollama** — local language model runtime (runs on YOUR hardware)
- 🔐 **Tailscale** — military-grade encryption + valid HTTPS certificates
- 📦 **Docker** — containerized deployment (production + beta stacks)

---

## 🚀 Quick Start — 3 Steps to Engage

### Step 1: Get Your Access Link

Ask your system admin for your JARVIS link. It looks like:
```
https://jarvis.YOUR_TAILNET.ts.net
```

Or if you're testing bleeding-edge features:
```
https://jarvis-beta.YOUR_TAILNET.ts.net
```

### Step 2: Approve Access in Tailscale

Your device needs to be **approved** on your Tailnet:

1. Go to [https://login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines)
2. Look for your device name (phone, laptop, etc.)
3. If it says "pending" — **approve it**
4. Wait ~10 seconds for the handshake to complete

**Status check:**
```bash
# On your device with Tailscale installed:
tailscale status
```

You should see `jarvis` and/or `jarvis-beta` in the list. If you see an IP next to them, you're connected.

### Step 3: Open & Log In

Click your JARVIS link in a browser. You'll see:

1. **First-time login screen** — Create your user account (username + password)
2. **Chat interface** — You're in the grid

---

## 💬 Using JARVIS — Chat Basics

### Starting a Conversation

1. Click the **text input box** at the bottom (glowing bar)
2. Type your question or prompt
3. Press **Enter** or click the **send button** (arrow icon)
4. The AI responds in real-time

**Example prompts:**
- "What is cyberpunk?"
- "Write a Python function that..."
- "Explain quantum computing like I'm five"
- "Generate a haiku about AI"

### Chat Features

| Feature | How to Use |
|---------|-----------|
| **Model Selection** | Dropdown at the top — choose your AI model |
| **New Chat** | Click the `+` button to start a fresh conversation |
| **Clear History** | Click the trash icon to reset the current chat |
| **Copy Response** | Hover over a response, click copy button |
| **Regenerate** | Click the refresh icon to re-answer the last question |

### Pro Tips

- **Long conversations**: Scroll up to see earlier messages
- **Code blocks**: AI will format code with syntax highlighting
- **Markdown support**: AI can generate formatted text, lists, tables
- **Context matters**: The AI remembers your entire conversation history in that chat thread

---

## 🔧 Model Selection

Different AI models have different strengths:

| Model | Best For | Speed |
|-------|----------|-------|
| `llama2` | General questions, writing, code | Fast |
| `mistral` | Creative writing, storytelling | Fast |
| `neural-chat` | Conversations, nuanced responses | Medium |
| *Others* | Varies — experiment! | Varies |

**How to switch:**
1. Look for the **model dropdown** (usually top of the chat)
2. Select a different model
3. Start typing — new conversations use the selected model

**Note:** Larger models use more GPU memory. If a model is slow or crashes, try a smaller one.

---

## ⚠️ Troubleshooting

### "Connection Refused" or "Can't Reach JARVIS"

**Checklist:**
1. ✅ Is Tailscale running on your device? (`tailscale status`)
2. ✅ Is your device approved? (Check admin console)
3. ✅ Try opening in a fresh browser tab or incognito window
4. ✅ Restart your browser
5. ✅ Ask your admin: "Is the JARVIS stack running?"

---

### Page Loads but Chat is Empty

1. **Refresh the page** (`Ctrl+R` or `Cmd+R`)
2. **Log out** (gear icon → Log Out) and log back in
3. **Clear browser cache** and refresh

---

### "Model Not Found" Error

The model hasn't finished downloading yet, or the admin needs to pull it.

**What to do:**
- Wait 1–2 minutes and refresh
- Try selecting a different model
- Contact admin if the problem persists

---

### Slow Responses or Timeouts

This means the AI is processing (especially on CPU-only hardware).

**What to do:**
- Be patient — some responses take 30+ seconds
- Try a smaller/faster model (see table above)
- Avoid very long prompts on slow models

---

## ⚙️ System Architecture & Reliability

### Recent Improvements (v1.0 Security Hardening)

JARVIS has been hardened with **12 critical remediation fixes** to improve reliability, security, and stability:

#### 🔒 Security Enhancements
- ✅ **Security Headers** — Added HTTP headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection) to prevent clickjacking and content injection attacks
- ✅ **Tailscale Image** — Sidecars use `tailscale/tailscale:unstable` for VIP support; operators should expect upstream changes on upgrade
- ✅ **Safe Configuration Updates** — Secure parsing of configuration files prevents injection vulnerabilities

#### 🛡️ Stability & Resource Management
- ✅ **Resource Limits** — CPU and memory limits enforced (4 CPU cores, 8GB max per container) prevent out-of-memory crashes
- ✅ **Robust Error Handling** — Added error traps with line-number reporting for faster issue diagnosis
- ✅ **Improved Container Detection** — Fixed race conditions in Tailscale readiness checks

#### 🔧 Operational Improvements
- ✅ **Consistent Networking** — Both production and beta stacks now use identical network modes for reliability
- ✅ **Dynamic Volume Cleanup** — Stack destruction now safely handles volumes even if project directory is renamed
- ✅ **Better Dialog Feedback** — TUI now distinguishes user cancellations from actual errors
- ✅ **Optimized Log Parsing** — Robust YAML parsing prevents configuration errors from formatting changes

#### 📊 Performance Optimizations
- ✅ **Cleaned Up TUI** — Removed unnecessary temporary file operations (faster startup)
- ✅ **Consistent Tailscale Serve** — Both prod and beta now use identical HTTPS/HTTP proxying syntax

**Translation:** Your JARVIS deployment is now more secure, more stable, and more resilient to edge cases and operator error.

---

## 🔐 Security & Privacy

- ✅ **Your data stays private** — everything runs on your organization's hardware
- ✅ **End-to-end encrypted** — Tailscale encrypts your connection
- ✅ **No cloud uploads** — conversations don't leave your network
- ✅ **Hardened headers** — Network-level defenses against XSS and clickjacking attacks
- ⚠️ **Admin can see logs** — don't assume conversations are 100% private from your admin

---

## 🎮 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Send message |
| `Shift+Enter` | New line in message |
| `Ctrl/Cmd+K` | Search/command menu |
| `Esc` | Close modals |

---

## 🌌 Advanced Tips

### Prompt Engineering

The AI responds better to well-structured prompts:

```
❌ Bad:  "write code"
✅ Good: "Write a Python function that counts vowels in a string. Include comments."

❌ Bad:  "explain ai"
✅ Good: "Explain how transformers work in language models, in 3 paragraphs for a technical audience."
```

### Using Code Output

- The AI generates syntax-highlighted code blocks
- Click the copy button to copy code to your clipboard
- Paste into your editor and test locally

### Continuing Conversations

Each chat thread remembers context. The AI knows what you asked earlier in that conversation. Start a **new chat** when switching topics dramatically.

---

## 📞 Support

**Having issues?**
- Check this guide (you might find the answer above)
- Contact your system admin
- Check the [JARVIS Troubleshooting Guide](./TROUBLESHOOTING.md) for deeper dives

---

## 🚪 Logging Out

When you're done:
1. Click the **gear icon** (⚙️) in the top-right corner
2. Select **Log Out**
3. Close the browser tab

Your conversations are saved (unless you delete them), so you can pick up where you left off next time.

---

> *Stay frosty. The grid awaits.*
>
> **JARVIS v1.0** — *Neural Interface Ready*
