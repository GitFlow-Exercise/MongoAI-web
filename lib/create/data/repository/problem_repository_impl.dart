import 'package:mongo_ai/core/exception/app_exception.dart';
import 'package:mongo_ai/core/result/result.dart';
import 'package:mongo_ai/create/data/data_source/problem_data_source.dart';
import 'package:mongo_ai/create/data/mapper/problem_mapper.dart';
import 'package:mongo_ai/create/domain/model/problem.dart';
import 'package:mongo_ai/create/domain/repository/problem_repository.dart';

class ProblemRepositoryImpl implements ProblemRepository {
  final ProblemDataSource _dataSource;

  const ProblemRepositoryImpl({required ProblemDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<void, AppException>> createProblems(
    List<Problem> problems,
    int workbookId,
  ) async {
    try {
      await _dataSource.createProblems(
        problems.map((e) => e.toProblemDto(workbookId)).toList(),
      );

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        AppException.remoteDataBase(
          message: '문제 생성 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<Result<List<Problem>, AppException>> getProblemsByWorkbookId(
      int workbookId,
      ) async {
    try {
      final problems = await _dataSource.getProblemsByWorkbookId(workbookId);

      return Result.success(problems.map((e) => e.toProblem()).toList());
    } catch (e) {
      return Result.error(
        AppException.remoteDataBase(
          message: '문제 조회 중 오류가 발생했습니다.',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
}
