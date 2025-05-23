import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_exception.freezed.dart';

@freezed
sealed class AppException with _$AppException implements Exception {
  const AppException._();

  const factory AppException.network({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = NetworkException;

  const factory AppException.remoteDataBase({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = RemoteDataBaseException;

  const factory AppException.localDataBase({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = localDataBaseException;

  const factory AppException.openAIType({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = OpenAITypeException;

  const factory AppException.filePick({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = FilePickException;

  const factory AppException.unknown({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnknownException;

  const factory AppException.invalidEmail({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = InvalidEmailException;

  const factory AppException.invalidPassword({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = InvalidPasswordException;

  const factory AppException.emailAlreadyExist({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = EmailAlreadyExistException;

  const factory AppException.pdfDownload({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = PdfDownloadException;

  const factory AppException.unAuthorized({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnAuthorizedException;

  const factory AppException.invalidOtp({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = InvalidOtpException;

  const factory AppException.tempStore({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = TempStoreException;

  const factory AppException.privacyPolicies({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = PrivacyPoliciesException;

  const factory AppException.unknownUser({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnknownUserException;

  String get userFriendlyMessage {
    switch (this) {
      case NetworkException():
        return '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case RemoteDataBaseException():
      case localDataBaseException():
        return '데이터를 불러오지 못했습니다.';
      case OpenAITypeException():
        return '올바르지 않은 타입입니다.';
      case FilePickException():
        return '파일을 정상적으로 불러오지 못했습니다.';
      case UnknownException():
        return '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case InvalidEmailException():
        return '유효하지 않은 이메일 주소입니다.';
      case InvalidPasswordException():
        return '유효하지 않은 비밀번호입니다.';
      case EmailAlreadyExistException():
        return '이미 존재하는 이메일입니다.';
      case PdfDownloadException():
        return '다운로드 중 에러가 발생하였습니다.';
      case UnAuthorizedException():
        return '인증되지 않은 사용자입니다.';
      case InvalidOtpException():
        return '유효하지 않은 인증번호입니다.';
      case TempStoreException():
        return '오류가 발생했습니다. 다시 시도해주세요.';
      case UnknownUserException():
        return '사용자를 불러올 수 없습니다.';
      case PrivacyPoliciesException():
        return '개인정보처리방침을 불러올 수 없습니다.';
    }
  }
}
