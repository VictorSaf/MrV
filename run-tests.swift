#!/usr/bin/env swift

// Quick test runner script
// Run with: swift run-tests.swift

import Foundation

print("""
╔══════════════════════════════════════════════════════════════╗
║          🧪 MULTI-AGENT SYSTEM QUICK TESTS 🧪                ║
╚══════════════════════════════════════════════════════════════╝

This script performs basic validation tests:
✓ Project structure check
✓ File existence verification
✓ Build system validation

For comprehensive tests, run the app and use:
  Menu → Run System Tests (⌘⇧T)

""")

print("📁 Checking project structure...")
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath

let requiredFiles = [
    "MrVAgent/Services/Orchestration/AgentCoordinator.swift",
    "MrVAgent/Services/Orchestration/ParallelAIOrchestrator.swift",
    "MrVAgent/Services/Orchestration/BackgroundProcessor.swift",
    "MrVAgent/Services/MrVConsciousness.swift",
    "MrVAgent/Services/ModelRouter.swift",
    "MrVAgent/FluidReality/FluidRealityEngine.swift",
    "MrVAgent/Tests/MultiAgentSystemTests.swift"
]

var allFilesExist = true
for file in requiredFiles {
    let fullPath = "\(currentPath)/\(file)"
    if fileManager.fileExists(atPath: fullPath) {
        print("   ✅ \(file)")
    } else {
        print("   ❌ \(file) - NOT FOUND")
        allFilesExist = false
    }
}

if allFilesExist {
    print("\n✅ All required files present\n")
} else {
    print("\n❌ Some files are missing\n")
    exit(1)
}

print("🔨 Testing build system...")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
task.arguments = ["build"]

let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe

do {
    try task.run()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    if task.terminationStatus == 0 {
        print("   ✅ Build successful")

        // Extract build time
        if let buildLine = output.components(separatedBy: "\n").first(where: { $0.contains("Build complete") }) {
            print("   \(buildLine.trimmingCharacters(in: .whitespaces))")
        }
    } else {
        print("   ❌ Build failed")
        print(output)
        exit(1)
    }
} catch {
    print("   ❌ Error running build: \(error)")
    exit(1)
}

print("""

╔══════════════════════════════════════════════════════════════╗
║                    ✅ VALIDATION PASSED ✅                   ║
╚══════════════════════════════════════════════════════════════╝

📊 Summary:
   • Project structure: ✓
   • All required files: ✓
   • Build system: ✓

🚀 Next Steps:
   1. Run the app: swift run
   2. Use menu: Run System Tests (⌘⇧T)
   3. Or import tests in your code:

      import MultiAgentSystemTests
      await runMultiAgentTests()

📝 For full test details, see:
   MrVAgent/Tests/MultiAgentSystemTests.swift

""")
