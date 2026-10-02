import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

class CompanyService {
  final CompanyRepository repository;

  const CompanyService({required this.repository});

  Future<Company?> getCurrent() => repository.getCurrent();

  Future<Company> update(Company company) => repository.update(company);
}
