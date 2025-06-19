import 'dart:async';

import 'package:mongo_ai/auth/data/data_source/auth_data_source.dart';
import 'package:mongo_ai/auth/domain/model/auth_state_change.dart';
import 'package:mongo_ai/auth/domain/repository/auth_repository.dart';
import 'package:mongo_ai/core/exception/app_exception.dart';
import 'package:mongo_ai/core/result/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSource _authDataSource;
  StreamSubscription<AuthState>? _authSubscription;

  // 리스너 목록
  final List<void Function(AuthStateChange)> _listeners = [];

  AuthRepositoryImpl({required AuthDataSource authDataSource})
      : _authDataSource = authDataSource {
    _startAuthStateListening();
  }

  @override
  Stream<AuthState> get authStateChanges => _authDataSource.authStateChanges;

  //TODO: Google Oauth Migration
  // 내부적으로 리스닝 시작 메서드
  void _startAuthStateListening() {
    _authSubscription?.cancel();
    _authSubscription = authStateChanges.listen((authState) {
      final event = authState.event;
      final session = authState.session;

      if (event == AuthChangeEvent.signedIn) {
        final provider = getUserProvider();
        final user = session?.user;

        if (provider == 'google') {
          // Google 로그인은 비동기 처리가 필요하므로 별도 처리
          _handleGoogleSignInAndNotify(user);
        } else {
          _notifyListeners(const AuthStateChange.signedIn());
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _notifyListeners(const AuthStateChange.signedOut());
      }
    });
  }

  // Google 로그인 처리 및 이벤트 발행
  Future<void> _handleGoogleSignInAndNotify(User? user) async {
    final result = await handleGoogleSignIn(user);
    switch (result) {
      case Success():
      // 첫 로그인 여부 확인(팀 선택 미완료인지 아닌지)
        final hasTeamNotSelected = !isPreferredTeamSelected;
        _notifyListeners(
          AuthStateChange.signedInWithGoogle(hasTeamNotSelected: hasTeamNotSelected),
        );
        break;
      case Error(error: final error):
        _notifyListeners(AuthStateChange.signInFailed(message: error.message));
        break;
    }
  }

  // 모든 리스너에게 이벤트 전달
  void _notifyListeners(AuthStateChange change) {
    final listeners = List<void Function(AuthStateChange)>.from(_listeners);
    for (final listener in listeners) {
      listener(change);
    }
    notifyListeners();
  }

  @override
  Future<Result<void, AppException>> handleGoogleSignIn(User? user) async {
    try {
      if (user == null) {
        return Result.error(
          AppException.unknownUser(
            message: '사용자 정보를 찾을 수 없습니다.',
            stackTrace: StackTrace.current,
          ),
        );
      }

      if (!checkMetadata('is_initial_setup_user')) {
        // 구글 사용자 정보를 DB에 insert
        await saveUser();
        return const Result.success(null);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '구글 로그인 처리 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> signIn(
      String email,
      String password,
      ) async {
    try {
      await _authDataSource.login(email, password);
      // 로그인 성공
      notifyListeners();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.error(
        AppException.unknown(
          message: '이메일 또는 비밀번호가 일치하지 않습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      ); // 기타 인증 오류
    } catch (e) {
      // 기타 예외 (네트워크, 파싱 등)
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> signInWithGoogle() async {
    try {
      await _authDataSource.signInWithGoogle();
      // 로그인 성공
      notifyListeners();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.error(
        AppException.unknown(
          message: 'Google 로그인 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      ); // 기타 인증 오류
    } catch (e) {
      // 기타 예외 (네트워크, 파싱 등)
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> signOut() async {
    try {
      await _authDataSource.logout();
      notifyListeners();
      return const Result.success(null);
    } catch (e) {
      // 기타 예외 (네트워크, 파싱 등)
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> deleteUser(String id) async {
    try {
      await _authDataSource.deleteUser(id);
      notifyListeners();
      return const Result.success(null);
    } catch (e) {
      print(e);
      return Result.error(
        AppException.unknown(
          message: '유저를 삭제하던 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> signUp(
      String email,
      String password,
      ) async {
    try {
      await _authDataSource.signUp(email, password);

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<bool, AppException>> isEmailExist(String email) async {
    try {
      final response = await _authDataSource.isEmailExist(email);

      if (response) {
        return Result.error(
          AppException.emailAlreadyExist(
            message: '이미 존재하는 이메일입니다.',
            error: const AuthException('이미 존재하는 이메일입니다.'),
            stackTrace: StackTrace.current,
          ),
        );
      } else {
        return const Result.success(false);
      }
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> saveUser() async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppException.unAuthorized(
            message: '인증되지 않은 사용자입니다.',
            error: null,
            stackTrace: StackTrace.current,
          ),
        );
      }

      await _authDataSource.saveUser();

      // 메타데이터 업데이트
      await _authDataSource.updateUserMetadata('is_initial_setup_user', true);
      notifyListeners();
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> resetPassword(String password) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppException.unAuthorized(
            message: '인증되지 않은 사용자입니다.',
            error: null,
            stackTrace: StackTrace.current,
          ),
        );
      }

      final userResponse = await _authDataSource.resetPassword(password);
      if (userResponse.user == null) {
        return Result.error(
          AppException.unknown(
            message: '비밀번호 설정에 실패하였습니다.',
            error: null,
            stackTrace: StackTrace.current,
          ),
        );
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '알 수 없는 오류입니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> sendOtp(String email) async {
    try {
      await _authDataSource.sendOtp(email);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '인증번호 전송을 실패하였습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> verifyEmailOtp(
      String email,
      String otp,
      ) async {
    try {
      await _authDataSource.verifyEmailOtp(email, otp);

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '인증번호가 일치하지 않습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> verifyMagicLinkOtp(
      String email,
      String otp,
      ) async {
    try {
      await _authDataSource.verifyMagicLinkOtp(email, otp);

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '인증번호가 일치하지 않습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<String, AppException>> getCurrentUserEmail() async {
    final user = await _authDataSource.getCurrentUserEmail();

    if (user != null) {
      return Result.success(user);
    } else {
      return Result.error(
        AppException.unknownUser(
          message: '사용자 이메일을 불러오던 중 오류가 발생했습니다.',
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppException>> setIsPreferredTeamSelected(bool isSelect) async {
    try {
      await _authDataSource.updateUserMetadata('is_preferred_team_selected', isSelect);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: 'Metadata를 설정하던 중 오류가 발생했습니다: is_preferred_team_selected',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  bool get isAuthenticated {
    return _authDataSource.isAuthenticated();
  }

  @override
  bool get isInitialSetupUser {
    return _authDataSource.isInitialSetupUser();
  }

  @override
  bool get isPreferredTeamSelected {
    return _authDataSource.isPreferredTeamSelected();
  }

  @override
  String? get userId {
    return _authDataSource.userId();
  }

  @override
  bool checkMetadata(String key) {
    return _authDataSource.checkMetadata(key);
  }

  @override
  String? getUserProvider() {
    return _authDataSource.getUserProvider();
  }

  @override
  void addAuthStateListener(void Function(AuthStateChange) listener) {
    _listeners.add(listener);
  }

  @override
  void removeAuthStateListener(void Function(AuthStateChange) listener) {
    _listeners.remove(listener);
  }

  @override
  Future<Result<void, AppException>> saveSelectedTeamId(int teamId) async {
    try {
      await _authDataSource.saveSelectedTeamId(teamId);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.unknown(
          message: '팀 ID 저장 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  int? getSelectedTeamId() {
    return _authDataSource.getSelectedTeamId();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _listeners.clear();
    super.dispose();
  }
}
