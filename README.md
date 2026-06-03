# Q-Flow AI: AI-Powered Queue Management System

Q-Flow AI is a real-time, production-grade Queue Management System built from scratch using **Flutter** and **Cloud Firestore**. The application leverages reactive streams for instant updates and incorporates an AI-driven predictive waiting time engine to compute individual customer metrics dynamically.

---

## 📂 System Directory Structure

```text
C:\Users\Fujitsu\.gemini\antigravity\scratch\queue_management_system\
├── .firebaserc                # Firebase target configuration
├── firebase.json              # Firebase Hosting URL routing rewrites
├── server.js                  # Lightweight Node.js preview launcher
├── index.html                 # Interactive web sandbox dashboard
└── lib/
    ├── main.dart              # Application bootstrapper & Dracula theme
    ├── models/
    │   ├── business_model.dart # Implements counter metadata structures
    │   └── ticket_model.dart   # Implements queue ticket schemas
    ├── providers/
    │   └── queue_provider.dart # ChangeNotifier state & predictive math formulas
    ├── services/
    │   └── queue_service.dart  # Cloud Firestore transactions driver
    └── screens/
        ├── admin/
        │   └── admin_dashboard_screen.dart # Desk management & caller interface
        └── customer/
            ├── counter_selection_screen.dart # Department select portal
            └── live_tracker_screen.dart      # Real-time waiting time clock
```

---

## 1. Local Web Simulation Quickstart

If Python or Flutter SDKs are not locally configured in your system environment path, you can run our interactive split-screen simulation directly in your browser. This sandbox simulates the client-side streaming views and admin desk controller synced via memory-based state events.

### Step 1.1: Locate the Sandbox Files
Navigate to your project root directory containing the simulation bundle:
* **UI Bundle**: [index.html](file:///C:/Users/Fujitsu/.gemini/antigravity/scratch/queue_management_system/index.html)
* **Launch Server**: [server.js](file:///C:/Users/Fujitsu/.gemini/antigravity/scratch/queue_management_system/server.js)

### Step 1.2: Launch the Node.js Server
Execute the following commands in your terminal:
```bash
# Verify your local Node.js environment
node --version

# Run the localized web server
node server.js
```

### Step 1.3: Access the Live Simulator
Open your browser and navigate to:
👉 **[http://localhost:8080](http://localhost:8080)**

* **Customer Interface (Left Panel)**: Allows you to select service counters, generate ticket tokens, and track real-time position milestones.
* **Admin Desk Panel (Right Panel)**: Choose the corresponding counter from the dropdown to list waiting queues. Call incoming tokens (`Call Next Client`) or close sessions (`Complete Task`) and watch the customer panel reflect updates in real-time.

---

## 2. Flutter Web Production Optimization Flags

When building the Flutter application for production web deployment, optimize compilation configurations to avoid frame lags during live queue animations.

### The Production Build Command
Compile the application using the following optimized flags:
```bash
flutter build web --release --web-renderer canvaskit
```

### Web Renderers Comparison

| Web Renderer | Architecture | Bundle Size | Performance & Lag Prevention | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **CanvasKit** *(Recommended)* | WebAssembly + WebGL | ~2.8 MB | **Excellent** (GPU-accelerated, 60fps animations, zero layout rendering lags) | Enterprise portals, real-time dashboards |
| **HTML** | HTML Elements + CSS | ~0.8 MB | **Moderate** (Prone to layout issues, font inconsistencies, and rendering stutters) | Mobile web pages, text-heavy profiles |
| **Auto** | Dynamic fallback | Variable | **Dynamic** (Uses HTML on mobile, CanvasKit on desktop browsers) | General cross-device apps |

### Why CanvasKit Prevents UI Lag:
1. **WebGL Canvas Rendering**: Draws the entire UI pixel-by-pixel using a GPU-accelerated canvas.
2. **WebAssembly Execution**: Computes complex waiting time math and state-changes on compiled Wasm routines rather than JS interpreters, preventing UI freezing.
3. **Layout Consistency**: Eliminates browser rendering engine inconsistencies for fonts, shadows, and card elevations.

---

## 3. Complete Firebase Hosting Pipeline

Host the compiled production-ready Flutter web app on Firebase Hosting using our pre-configured automation.

### Step 3.1: Log in & Verify Project Binding
Ensure you have the Firebase CLI tools installed. Authenticate your account:
```bash
# Install CLI tools globally
npm install -g firebase-tools

# Log in to your Google Account
firebase login
```

### Step 3.2: Verify Configurations
Ensure your project contains the two pre-defined deployment configuration files in the root folder:

* **[firebase.json](file:///C:/Users/Fujitsu/.gemini/antigravity/scratch/queue_management_system/firebase.json)**:
  ```json
  {
    "hosting": {
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  }
  ```
* **[.firebaserc](file:///C:/Users/Fujitsu/.gemini/antigravity/scratch/queue_management_system/.firebaserc)**:
  Replace the project ID placeholder with your actual Firebase console ID:
  ```json
  {
    "projects": {
      "default": "your-firebase-project-id"
    }
  }
  ```

### Step 3.3: Interactive Initialization (Optional)
If you prefer configuring hosting settings manually via prompt selections, run:
```bash
firebase init hosting
```
* **What is your public directory?** Type: `build/web`
* **Configure as a single-page app?** Type: `Yes` (Important: Handles custom URL rewrites)
* **Set up automatic builds and deploys with GitHub?** Type: `No`
* **File build/web/index.html already exists. Overwrite?** Type: `No`

### Step 3.4: Production Build & Deployment Command
Compile and push your workspace bundle to the live servers:
```bash
# Build optimized CanvasKit assets
flutter build web --release --web-renderer canvaskit

# Deploy static files to hosting
firebase deploy --only hosting
```

live demo-(https://smartqueueautomation.netlify.app/)
