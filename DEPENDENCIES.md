# NCC External Dependencies Documentation

## Required Software Dependencies

### Blender (3D Rendering)
**Purpose**: Required for `render_4angles.py` script to perform 3D model rendering and visualization.

**Installation**:
1. Download Blender from https://www.blender.org/download/
2. Install Blender (recommended version: 3.6+)
3. Ensure Blender is added to system PATH or run scripts from Blender's Python environment

**Usage**:
- The `render_4angles.py` script uses Blender's Python API (`bpy`)
- Run with: `blender --background --python render_4angles.py`

**Alternative**: If Blender installation is not feasible, consider:
- Using cloud rendering services
- Replacing with alternative 3D rendering libraries (e.g., PyVista, Trimesh)
- Converting to web-based visualization

**Status**: Not currently installed - optional for 3D rendering capabilities

### Python Environment Setup
**Dependencies File**: `requirements.txt` (created)
**Installation**: `pip install -r requirements.txt`

**Virtual Environment**: `.venv/` (already configured with Python 3.14.2)

### Node.js Dependencies
**Installation**: `npm install` (dependencies defined in `package.json`)
**Key Dependencies**:
- express: Web server
- ws: WebSocket support
- jasonwebtoken: Authentication
- bcryptjs: Password hashing
- cors: Cross-origin support

## API Keys Required
Configure the following in `.env` file:
- `YT_API_KEY`: YouTube Data API v3 key
- `REDDIT_CLIENT_ID`: Reddit API client ID
- `REDDIT_CLIENT_SECRET`: Reddit API client secret

## System Requirements
- **OS**: Windows 10/11 (current environment)
- **Python**: 3.8+ (3.14.2 configured)
- **Node.js**: 18.0+ (defined in package.json)
- **PowerShell**: 7.0+ (for automation scripts)
- **Git**: For version control

## Verification Commands
```bash
# Python dependencies
pip install -r requirements.txt
python -c "import requests, bs4, pandas; print('Python deps OK')"

# Node.js dependencies
npm install
npm test

# Blender check
blender --version
```
