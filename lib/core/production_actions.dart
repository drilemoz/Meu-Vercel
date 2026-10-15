import 'errors.dart';
import 'models.dart';

/// Valida operações que podem alterar o site público ANTES de enviar um POST.
/// Nunca confia em dados antigos de cache para confirmar vínculo com o projeto.
class ProductionActions {
  static void requireDeployment(Deployment deployment, String projectId,
      {required bool preview}) {
    if (projectId.isEmpty || deployment.projectId == null ||
        deployment.projectId != projectId) {
      throw const ApiFailure(FailureKind.invalid,
        'Não foi possível confirmar online o projeto deste deploy. Atualize os dados.');
    }
    if (deployment.status != 'READY') {
      throw const ApiFailure(FailureKind.invalid,
        'Apenas deploys com status READY podem ser usados nesta operação.');
    }
    if (preview && deployment.environment != 'preview') {
      throw const ApiFailure(FailureKind.invalid,
        'Selecione um deploy Preview concluído.');
    }
    if (!preview && deployment.environment != 'production') {
      throw const ApiFailure(FailureKind.invalid,
        'Rollback exige um deploy anterior de Production.');
    }
  }

}
