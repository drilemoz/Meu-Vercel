/// Regra de nomenclatura do painel Vercel: 1 a 100 caracteres, minúsculas,
/// dígitos, ponto, sublinhado ou hífen, sem a sequência proibida "---".
bool validProjectName(String name) =>
    name.length <= 100 &&
    RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(name) &&
    !name.contains('---');
