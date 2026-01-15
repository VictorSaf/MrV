import Foundation
import SQLite3

/// SQLite database manager for Mr.V Agent memory system
/// Handles all database operations with thread-safe access
actor SQLiteManager {

    // MARK: - Properties

    private var db: OpaquePointer?
    private let dbPath: String
    private var isInitialized = false

    // MARK: - Errors

    enum DatabaseError: LocalizedError {
        case connectionFailed(String)
        case queryFailed(String)
        case notInitialized
        case invalidData
        case constraintViolation(String)

        var errorDescription: String? {
            switch self {
            case .connectionFailed(let message):
                return "Database connection failed: \(message)"
            case .queryFailed(let message):
                return "Query failed: \(message)"
            case .notInitialized:
                return "Database not initialized"
            case .invalidData:
                return "Invalid data format"
            case .constraintViolation(let message):
                return "Constraint violation: \(message)"
            }
        }
    }

    // MARK: - Initialization

    init(dbPath: String? = nil) {
        // Use application support directory by default
        if let customPath = dbPath {
            self.dbPath = customPath
        } else {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let mrVDirectory = appSupport.appendingPathComponent("MrVAgent", isDirectory: true)

            // Create directory if needed
            try? fileManager.createDirectory(at: mrVDirectory, withIntermediateDirectories: true)

            self.dbPath = mrVDirectory.appendingPathComponent("mrv_memory.db").path
        }
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Database Lifecycle

    /// Initialize database connection and create schema
    func initialize() async throws {
        guard !isInitialized else { return }

        // Open database connection
        var db: OpaquePointer?
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(errorMessage)
        }

        self.db = db

        // Enable foreign keys
        try await execute("PRAGMA foreign_keys = ON;")

        // Load and execute schema
        try await loadSchema()

        isInitialized = true
        print("✅ SQLite database initialized at: \(dbPath)")
    }

    /// Load and execute schema from SQL file
    private func loadSchema() async throws {
        // Get schema SQL file path
        let bundle = Bundle.main
        guard let schemaPath = bundle.path(forResource: "Schema", ofType: "sql", inDirectory: "Memory/Database") else {
            // If running in development, try alternative path
            let projectPath = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .appendingPathComponent("Schema.sql")

            guard let schemaSQL = try? String(contentsOf: projectPath, encoding: .utf8) else {
                throw DatabaseError.queryFailed("Schema.sql not found")
            }

            try await executeMultiple(schemaSQL)
            return
        }

        let schemaSQL = try String(contentsOfFile: schemaPath, encoding: .utf8)
        try await executeMultiple(schemaSQL)
    }

    // MARK: - Query Execution

    /// Execute a single SQL statement (INSERT, UPDATE, DELETE, CREATE, etc.)
    func execute(_ sql: String, parameters: [any SQLiteValue] = []) async throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        var statement: OpaquePointer?
        defer {
            sqlite3_finalize(statement)
        }

        // Prepare statement
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        // Bind parameters
        try bindParameters(statement: statement, parameters: parameters)

        // Execute
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE && result != SQLITE_ROW {
            let errorMessage = String(cString: sqlite3_errmsg(db))

            // Check if constraint violation
            if result == SQLITE_CONSTRAINT {
                throw DatabaseError.constraintViolation(errorMessage)
            }

            throw DatabaseError.queryFailed("Execution failed: \(errorMessage)")
        }
    }

    /// Execute multiple SQL statements (for schema loading)
    private func executeMultiple(_ sql: String) async throws {
        // Split by semicolons (simple split, doesn't handle strings with semicolons)
        let statements = sql.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for statement in statements {
            try await execute(statement)
        }
    }

    /// Query and return rows
    func query(_ sql: String, parameters: [any SQLiteValue] = []) async throws -> [[String: any SQLiteValue]] {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        var statement: OpaquePointer?
        defer {
            sqlite3_finalize(statement)
        }

        // Prepare statement
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        // Bind parameters
        try bindParameters(statement: statement, parameters: parameters)

        // Fetch results
        var rows: [[String: any SQLiteValue]] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: any SQLiteValue] = [:]

            let columnCount = sqlite3_column_count(statement)
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let value = extractValue(statement: statement, columnIndex: i)
                row[columnName] = value
            }

            rows.append(row)
        }

        return rows
    }

    /// Query and return single row
    func queryOne(_ sql: String, parameters: [any SQLiteValue] = []) async throws -> [String: any SQLiteValue]? {
        let rows = try await query(sql, parameters: parameters)
        return rows.first
    }

    // MARK: - Parameter Binding

    private func bindParameters(statement: OpaquePointer?, parameters: [any SQLiteValue]) throws {
        guard let statement = statement else { return }

        for (index, value) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)

            switch value {
            case let string as String:
                sqlite3_bind_text(statement, bindIndex, string, -1, nil)
            case let int as Int:
                sqlite3_bind_int64(statement, bindIndex, Int64(int))
            case let int64 as Int64:
                sqlite3_bind_int64(statement, bindIndex, int64)
            case let double as Double:
                sqlite3_bind_double(statement, bindIndex, double)
            case let bool as Bool:
                sqlite3_bind_int(statement, bindIndex, bool ? 1 : 0)
            case let data as Data:
                _ = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, bindIndex, bytes.baseAddress, Int32(data.count), nil)
                }
            case let date as Date:
                // Store dates as ISO8601 strings
                let formatter = ISO8601DateFormatter()
                let dateString = formatter.string(from: date)
                sqlite3_bind_text(statement, bindIndex, dateString, -1, nil)
            case is NSNull:
                sqlite3_bind_null(statement, bindIndex)
            default:
                throw DatabaseError.invalidData
            }
        }
    }

    // MARK: - Value Extraction

    private func extractValue(statement: OpaquePointer?, columnIndex: Int32) -> any SQLiteValue {
        guard let statement = statement else { return NSNull() }

        let type = sqlite3_column_type(statement, columnIndex)

        switch type {
        case SQLITE_INTEGER:
            return sqlite3_column_int64(statement, columnIndex)
        case SQLITE_FLOAT:
            return sqlite3_column_double(statement, columnIndex)
        case SQLITE_TEXT:
            if let cString = sqlite3_column_text(statement, columnIndex) {
                return String(cString: cString)
            }
            return ""
        case SQLITE_BLOB:
            let blobPointer = sqlite3_column_blob(statement, columnIndex)
            let blobSize = sqlite3_column_bytes(statement, columnIndex)
            if let blobPointer = blobPointer {
                return Data(bytes: blobPointer, count: Int(blobSize))
            }
            return Data()
        case SQLITE_NULL:
            return NSNull()
        default:
            return NSNull()
        }
    }

    // MARK: - Convenience Methods

    /// Begin transaction
    func beginTransaction() async throws {
        try await execute("BEGIN TRANSACTION;")
    }

    /// Commit transaction
    func commit() async throws {
        try await execute("COMMIT;")
    }

    /// Rollback transaction
    func rollback() async throws {
        try await execute("ROLLBACK;")
    }

    /// Get last insert row ID
    func lastInsertRowId() -> Int64 {
        guard let db = db else { return 0 }
        return sqlite3_last_insert_rowid(db)
    }

    /// Count rows in table
    func count(table: String, where whereClause: String? = nil) async throws -> Int {
        var sql = "SELECT COUNT(*) as count FROM \(table)"
        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        if let row = try await queryOne(sql), let count = row["count"] as? Int64 {
            return Int(count)
        }

        return 0
    }

    /// Check if table exists
    func tableExists(_ tableName: String) async throws -> Bool {
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;"
        let rows = try await query(sql, parameters: [tableName])
        return !rows.isEmpty
    }

    /// Get database path
    func getDatabasePath() -> String {
        return dbPath
    }

    /// Get database size in bytes
    func getDatabaseSize() async throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: dbPath)
        return attributes[.size] as? Int64 ?? 0
    }

    /// Vacuum database (compact and optimize)
    func vacuum() async throws {
        try await execute("VACUUM;")
    }
}

// MARK: - SQLiteValue Protocol

protocol SQLiteValue {}

extension String: SQLiteValue {}
extension Int: SQLiteValue {}
extension Int64: SQLiteValue {}
extension Double: SQLiteValue {}
extension Float: SQLiteValue {}
extension Bool: SQLiteValue {}
extension Data: SQLiteValue {}
extension NSNull: SQLiteValue {}
extension Date: SQLiteValue {}  // Dates stored as ISO8601 strings or timestamps
