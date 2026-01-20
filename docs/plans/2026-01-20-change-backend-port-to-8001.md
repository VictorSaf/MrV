# Change Backend Port from 8000 to 8001 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update all source code and documentation to run backend on port 8001 instead of 8000.

**Architecture:** Simple configuration change across Python backend, Swift frontend, and documentation files. The backend's port checking logic already supports fallback ports, so we're just changing the preferred default.

**Tech Stack:** Python (FastAPI/Uvicorn), Swift (URLSession), Markdown documentation

---

## Task 1: Update Backend Default Port

**Files:**
- Modify: `backend/run.py:33`

**Step 1: Update preferred_port variable**

Change the preferred_port from 8000 to 8001:

```python
if __name__ == "__main__":
    host = "0.0.0.0"
    preferred_port = 8001  # Changed from 8000
```

**Step 2: Verify the change**

Read the file to confirm:

```bash
grep -n "preferred_port" backend/run.py
```

Expected output: `33:    preferred_port = 8001`

**Step 3: Commit backend port change**

```bash
cd backend
git add run.py
git commit -m "config: change backend preferred port to 8001"
```

---

## Task 2: Update Swift Frontend Default URL

**Files:**
- Modify: `MrVAgengtXcode/MrVAgent/MrVAgent/Services/Backends/RpdBackendService.swift:15`

**Step 1: Update default baseURL**

Change the default baseURL from port 8000 to 8001:

```swift
actor RpdBackendService {
    private let baseURL: String
    private let session: URLSession
    private var sessionId: String

    init(baseURL: String = "http://localhost:8001") {  // Changed from 8000
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.sessionId = UUID().uuidString
    }
```

**Step 2: Verify the change**

Read the file to confirm:

```bash
grep -n "localhost:800" MrVAgengtXcode/MrVAgent/MrVAgent/Services/Backends/RpdBackendService.swift
```

Expected output: `15:    init(baseURL: String = "http://localhost:8001") {`

**Step 3: Commit Swift frontend change**

```bash
cd MrVAgengtXcode/MrVAgent
git add MrVAgent/Services/Backends/RpdBackendService.swift
git commit -m "config: change frontend default backend URL to port 8001"
```

---

## Task 3: Update README Documentation

**Files:**
- Modify: `backend/README.md:82,84`

**Step 1: Update server start documentation**

Change both references from port 8000 to 8001:

```markdown
### Start Backend Server

```bash
python run.py
```

Server starts on `http://localhost:8001`

API Documentation: `http://localhost:8001/docs`
```

**Step 2: Verify the changes**

Read the lines to confirm:

```bash
grep -n "localhost:800" backend/README.md
```

Expected output showing port 8001 on lines 82 and 84.

**Step 3: Commit README changes**

```bash
cd backend
git add README.md
git commit -m "docs: update README to reflect port 8001"
```

---

## Task 4: Update VALIDATION Documentation

**Files:**
- Modify: `backend/VALIDATION.md:125`

**Step 1: Update deployment instructions**

Change the port reference in the Swift App section:

```markdown
### Swift App
1. Open MrVAgengtXcode/MrVAgent/MrVAgent.xcodeproj
2. Ensure backend is running on localhost:8001
3. Build and run
```

**Step 2: Verify the change**

Read the file to confirm:

```bash
grep -n "localhost:800" backend/VALIDATION.md
```

Expected output: `125:2. Ensure backend is running on localhost:8001`

**Step 3: Commit VALIDATION changes**

```bash
cd backend
git add VALIDATION.md
git commit -m "docs: update VALIDATION to reflect port 8001"
```

---

## Task 5: Update Implementation Plan Archive

**Files:**
- Modify: `docs/plans/2026-01-19-rpd-ganis-giu-cognitive-architecture.md:1604`

**Step 1: Update historical plan code snippet**

Change the archived Swift code example:

```swift
actor RpdBackendService {
    private let baseURL: String
    private let session: URLSession
    private var sessionId: String

    init(baseURL: String = "http://localhost:8001") {  // Changed from 8000
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.sessionId = UUID().uuidString
    }
```

**Step 2: Verify the change**

Read the line to confirm:

```bash
grep -n "localhost:800" docs/plans/2026-01-19-rpd-ganis-giu-cognitive-architecture.md
```

Expected output: `1604:    init(baseURL: String = "http://localhost:8001") {`

**Step 3: Commit plan archive update**

```bash
git add docs/plans/2026-01-19-rpd-ganis-giu-cognitive-architecture.md
git commit -m "docs: update historical plan to reflect port 8001"
```

---

## Task 6: Verify Backend Starts on Port 8001

**Files:**
- Test: `backend/run.py`

**Step 1: Kill any process on port 8000**

```bash
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
```

Expected: Process killed or no process found

**Step 2: Start backend with new configuration**

```bash
cd backend
source venv/bin/activate
python run.py &
BACKEND_PID=$!
sleep 2
```

Expected output: `✓ Starting server on 0.0.0.0:8001`

**Step 3: Verify backend responds on port 8001**

```bash
curl -s http://localhost:8001/health
```

Expected output: `{"status":"healthy","environment":"development"}`

**Step 4: Verify port 8000 is not in use**

```bash
curl -s http://localhost:8000/health 2>&1 | grep -q "Connection refused" && echo "✓ Port 8000 not in use" || echo "✗ Port 8000 still responding"
```

Expected: `✓ Port 8000 not in use`

**Step 5: Stop test backend**

```bash
kill $BACKEND_PID
```

**Step 6: Document verification results**

No commit needed - verification step only.

---

## Task 7: Create Consolidated Commit

**Files:**
- All modified files

**Step 1: Check git status across all repos**

```bash
cd /Users/victorsafta/work/1really1/MrVAgent
git status --short
cd backend
git status --short
cd ../MrVAgengtXcode/MrVAgent
git status --short
```

Expected: All changes should be committed from previous tasks.

**Step 2: Verify all repositories are clean**

All commits should already be made in previous tasks. This step confirms completion.

**Step 3: Document final state**

Create a summary of what was changed:

```bash
echo "Port Migration Summary:
- Backend preferred_port: 8000 → 8001
- Swift default URL: localhost:8000 → localhost:8001
- README.md: Updated port references
- VALIDATION.md: Updated deployment instructions
- Historical plan: Updated for accuracy

All changes committed and verified."
```

---

## Completion Checklist

- [x] Task 1: Updated backend/run.py preferred_port to 8001
- [x] Task 2: Updated Swift RpdBackendService default URL to 8001
- [x] Task 3: Updated README.md documentation
- [x] Task 4: Updated VALIDATION.md documentation
- [x] Task 5: Updated historical implementation plan
- [x] Task 6: Verified backend starts and responds on port 8001
- [x] Task 7: Confirmed all changes committed

## Testing Notes

After implementation, test the full stack:

1. Start backend: `cd backend && python run.py`
   - Should show: "✓ Starting server on 0.0.0.0:8001"

2. Open Xcode and build the Swift app
   - Should connect to localhost:8001 by default

3. Verify API access: `curl http://localhost:8001/health`
   - Should return: `{"status":"healthy",...}`

## Rollback Plan

If issues arise, revert commits:

```bash
cd backend
git revert HEAD~3  # Revert run.py, README, VALIDATION

cd ../MrVAgengtXcode/MrVAgent
git revert HEAD    # Revert Swift changes

cd ../..
git revert HEAD    # Revert plan archive
```

Then restart backend - it will use port 8000 again.
