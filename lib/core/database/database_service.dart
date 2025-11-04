import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'ai_assistant.db';
  static const int _databaseVersion = 2;

  // Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        theme_preference TEXT DEFAULT 'system',
        language TEXT DEFAULT 'tr'
      )
    ''');

    // Tasks tablosu
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        priority TEXT NOT NULL DEFAULT 'medium',
        due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_calendar_synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Calendar events tablosu
    await db.execute('''
      CREATE TABLE calendar_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        event_type TEXT DEFAULT 'personal',
        source TEXT DEFAULT 'manual',
        external_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Email accounts tablosu
    await db.execute('''
      CREATE TABLE email_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        email_address TEXT UNIQUE NOT NULL,
        provider TEXT NOT NULL,
        display_name TEXT,
        is_active INTEGER DEFAULT 1,
        last_sync TEXT,
        sync_enabled INTEGER DEFAULT 1,
        access_token TEXT,
        refresh_token TEXT,
        token_expires TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Emails tablosu
    await db.execute('''
      CREATE TABLE emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        message_id TEXT,
        thread_id TEXT,
        subject TEXT NOT NULL,
        from_email TEXT NOT NULL,
        from_name TEXT,
        to_emails TEXT NOT NULL,
        cc_emails TEXT,
        bcc_emails TEXT,
        plain_text TEXT,
        html_content TEXT,
        attachments TEXT,
        received_date TEXT,
        sent_date TEXT,
        email_status INTEGER NOT NULL DEFAULT 2,
        email_importance INTEGER NOT NULL DEFAULT 0,
        is_read INTEGER NOT NULL DEFAULT 0,
        is_starred INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_spam INTEGER NOT NULL DEFAULT 0,
        folder TEXT NOT NULL DEFAULT 'inbox',
        labels TEXT,
        size_bytes INTEGER,
        external_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES email_accounts (id) ON DELETE CASCADE
      )
    ''');

    // Email analytics tablosu
    await db.execute('''
      CREATE TABLE email_analytics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        message_id TEXT NOT NULL,
        sender TEXT,
        subject TEXT,
        ai_category TEXT,
        ai_priority TEXT,
        ai_summary TEXT,
        extracted_tasks TEXT,
        extracted_events TEXT,
        is_processed INTEGER DEFAULT 0,
        processed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES email_accounts (id) ON DELETE CASCADE
      )
    ''');

    // Notifications tablosu
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        related_id INTEGER,
        is_read INTEGER DEFAULT 0,
        scheduled_for TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Email templates tablosu
    await db.execute('''
      CREATE TABLE email_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        subject TEXT,
        body TEXT,
        is_default INTEGER DEFAULT 0,
        usage_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // User settings tablosu
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT,
        category TEXT DEFAULT 'general',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, setting_key)
      )
    ''');

    // Index'leri oluştur
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Tasks index'leri
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');

    // Calendar events index'leri
    await db.execute('CREATE INDEX idx_calendar_user_id ON calendar_events(user_id)');
    await db.execute('CREATE INDEX idx_calendar_start_time ON calendar_events(start_time)');

    // Email accounts index'leri
    await db.execute('CREATE INDEX idx_email_accounts_user_id ON email_accounts(user_id)');

    // Emails index'leri
    await db.execute('CREATE INDEX idx_emails_user_id ON emails(user_id)');
    await db.execute('CREATE INDEX idx_emails_account_id ON emails(account_id)');
    await db.execute('CREATE INDEX idx_emails_folder ON emails(folder)');
    await db.execute('CREATE INDEX idx_emails_status ON emails(email_status)');
    await db.execute('CREATE INDEX idx_emails_external_id ON emails(external_id)');

    // Email analytics index'leri
    await db.execute('CREATE INDEX idx_email_analytics_account_id ON email_analytics(account_id)');
    await db.execute('CREATE INDEX idx_email_analytics_processed ON email_analytics(is_processed)');

    // Notifications index'leri
    await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_read ON notifications(is_read)');

    // User settings index'leri
    await db.execute('CREATE INDEX idx_user_settings_user_id ON user_settings(user_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1'den 2'ye geçiş: emails tablosu ve ilgili tabloları ekle
    if (oldVersion < 2) {
      // Emails tablosu yoksa oluştur
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            account_id INTEGER NOT NULL,
            message_id TEXT,
            thread_id TEXT,
            subject TEXT NOT NULL,
            from_email TEXT NOT NULL,
            from_name TEXT,
            to_emails TEXT NOT NULL,
            cc_emails TEXT,
            bcc_emails TEXT,
            plain_text TEXT,
            html_content TEXT,
            attachments TEXT,
            received_date TEXT,
            sent_date TEXT,
            email_status INTEGER NOT NULL DEFAULT 2,
            email_importance INTEGER NOT NULL DEFAULT 0,
            is_read INTEGER NOT NULL DEFAULT 0,
            is_starred INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            is_spam INTEGER NOT NULL DEFAULT 0,
            folder TEXT NOT NULL DEFAULT 'inbox',
            labels TEXT,
            size_bytes INTEGER,
            external_id TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (account_id) REFERENCES email_accounts (id) ON DELETE CASCADE
          )
        ''');

        // Email index'lerini oluştur
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emails_user_id ON emails(user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emails_account_id ON emails(account_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emails_folder ON emails(folder)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emails_status ON emails(email_status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emails_external_id ON emails(external_id)');
      } catch (e) {
        // Tablo zaten varsa hata verme
        debugPrint('Error creating emails table: $e');
      }

      // Email analytics tablosu yoksa oluştur
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS email_analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER NOT NULL,
            message_id TEXT NOT NULL,
            sender TEXT,
            subject TEXT,
            ai_category TEXT,
            ai_priority TEXT,
            ai_summary TEXT,
            extracted_tasks TEXT,
            extracted_events TEXT,
            is_processed INTEGER DEFAULT 0,
            processed_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (account_id) REFERENCES email_accounts (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_email_analytics_account_id ON email_analytics(account_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_email_analytics_processed ON email_analytics(is_processed)');
      } catch (e) {
        debugPrint('Error creating email_analytics table: $e');
      }

      // Email templates tablosu yoksa oluştur
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS email_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            subject TEXT,
            body TEXT,
            is_default INTEGER DEFAULT 0,
            usage_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Error creating email_templates table: $e');
      }

      // User settings tablosu yoksa oluştur
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            setting_key TEXT NOT NULL,
            setting_value TEXT,
            category TEXT DEFAULT 'general',
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(user_id, setting_key)
          )
        ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id)');
      } catch (e) {
        debugPrint('Error creating user_settings table: $e');
      }
    }
  }

  // Şifreleme için basit hash fonksiyonu
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Veritabanı kapatma
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  // Veritabanını temizleme
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_settings');
      await txn.delete('notifications');
      await txn.delete('email_analytics');
      await txn.delete('email_templates');
      await txn.delete('emails');
      await txn.delete('calendar_events');
      await txn.delete('tasks');
      await txn.delete('email_accounts');
      await txn.delete('users');
    });
  }
}
