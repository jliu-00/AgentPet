<div align="center">
  <img src="Assets/ratRest.png" width="500" alt="AgentPet" />
</div>

<div align="right">
  <a href="README_zh.md">中文</a> | <strong>English</strong>
</div>

# AgentPet

AgentPet is a minimalist macOS menu bar application that adds a lively, animated pet to your status bar. 

### What is it for?
AgentPet is designed to act as a **background task indicator**, specifically tailored for AI agents, developers, and autonomous scripts. 
Instead of looking at boring loading spinners or terminal logs, you can watch a cute little animal run across your menu bar whenever your AI agent or background script is actively "thinking", "working", or generating content. When the task is finished, your pet goes to sleep.

### Features
- **Zero-Config Antigravity Support**: Native integration. Just launch the app and it instantly monitors the Antigravity Agent logs. No scripts or setup needed.
- **Multiple Pets**: Switch between a sleek Cat or a chubby Fancy Rat at any time from the dropdown menu. Future updates will add more pets.
- **Dynamic Animation**: The pet runs when there's an active workload, and rests/sleeps when idle.

### How to use
1. Launch `AgentPet.app`. The pet will immediately appear on the right side of your macOS menu bar.
2. Click the pet in the menu bar to open the dropdown menu to switch between different shapes. As long as the AI is thinking, the pet will run.

### Custom Script Monitoring (For developers)
AgentPet also listens to a local status file as a fallback, allowing you to hook it up to any other custom script or workload.
Write the word `working` into the status file:
```bash
echo "working" > ~/.agentpet_status
```

**To make the pet rest:**
Write anything else (or clear the file):
```bash
echo "idle" > ~/.agentpet_status
```
