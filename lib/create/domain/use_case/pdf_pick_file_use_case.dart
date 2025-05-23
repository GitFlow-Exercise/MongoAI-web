import 'package:mongo_ai/core/exception/app_exception.dart';
import 'package:mongo_ai/core/result/result.dart';
import 'package:mongo_ai/create/domain/model/pick_file.dart';
import 'package:mongo_ai/create/domain/repository/file_picker_repository.dart';

class PdfPickFileUseCase {
  final FilePickerRepository _filePickerRepository;

  const PdfPickFileUseCase({required FilePickerRepository filePickerRepository})
    : _filePickerRepository = filePickerRepository;

  Future<Result<PickFile?, AppException>> execute() async {
    return await _filePickerRepository.selectPdf();
  }
}
