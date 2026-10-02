import '../entities/company.dart';

abstract class CompanyRepository {
  Future<Company?> getCurrent();
  Future<Company> update(Company company);
}
