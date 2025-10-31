import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  // Yeni kullanıcı oluştur
  Future<User> createUser({
    required String email,
    required String name,
    required String password,
    String themePreference = 'system',
    String language = 'tr',
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final passwordHash = _databaseService.hashPassword(password);

    final user = User(
      email: email,
      name: name,
      passwordHash: passwordHash,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      themePreference: themePreference,
      language: language,
    );

    final id = await db.insert('users', user.toDatabase());
    return user.copyWith(id: id);
  }

  // ID'ye göre kullanıcı getir
  Future<User?> getUserById(int id) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return User.fromDatabase(maps.first);
  }

  // E-posta'ya göre kullanıcı getir
  Future<User?> getUserByEmail(String email) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return User.fromDatabase(maps.first);
  }

  // Giriş kontrolü
  Future<User?> authenticate(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user == null) return null;

    final passwordHash = _databaseService.hashPassword(password);
    if (user.passwordHash == passwordHash) {
      return user;
    }

    return null;
  }

  // Kullanıcı bilgilerini güncelle
  Future<int> updateUser(User user) async {
    final db = await _databaseService.database;
    final updatedUser = user.copyWith(updatedAt: DateTime.now());

    return await db.update(
      'users',
      updatedUser.toDatabase(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Kullanıcı adını güncelle
  Future<int> updateUserName(int userId, String newName) async {
    final db = await _databaseService.database;

    return await db.update(
      'users',
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Şifre güncelle
  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await _databaseService.database;
    final passwordHash = _databaseService.hashPassword(newPassword);

    return await db.update(
      'users',
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Tema tercihini güncelle
  Future<int> updateUserTheme(int userId, String themePreference) async {
    final db = await _databaseService.database;

    return await db.update(
      'users',
      {
        'theme_preference': themePreference,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Dil tercihini güncelle
  Future<int> updateUserLanguage(int userId, String language) async {
    final db = await _databaseService.database;

    return await db.update(
      'users',
      {
        'language': language,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Kullanıcı durumunu güncelle (aktif/pasif)
  Future<int> updateUserStatus(int userId, bool isActive) async {
    final db = await _databaseService.database;

    return await db.update(
      'users',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // E-posta adresi daha önce kullanılmış mı kontrol et
  Future<bool> isEmailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // Tüm kullanıcıları getir (admin için)
  Future<List<User>> getAllUsers() async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => User.fromDatabase(map)).toList();
  }

  // Aktif kullanıcıları getir
  Future<List<User>> getActiveUsers() async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => User.fromDatabase(map)).toList();
  }

  // Kullanıcı sil (soft delete)
  Future<int> deleteUser(int userId) async {
    return await updateUserStatus(userId, false);
  }

  // Kullanıcıyı tamamen sil
  Future<int> deleteUserPermanently(int userId) async {
    final db = await _databaseService.database;

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Kullanıcı sayısını al
  Future<int> getUsersCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Aktif kullanıcı sayısını al
  Future<int> getActiveUsersCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE is_active = ?',
      [1],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Belirli bir tarihten sonraki kullanıcıları getir
  Future<List<User>> getUsersCreatedAfter(DateTime date) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'created_at > ?',
      whereArgs: [date.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => User.fromDatabase(map)).toList();
  }

  // Arama fonksiyonu
  Future<List<User>> searchUsers(String query) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => User.fromDatabase(map)).toList();
  }
}