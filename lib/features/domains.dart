import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';

class DomainsScreen extends StatefulWidget {
  const DomainsScreen(this.app, this.project, {super.key});
  final AppController app;
  final Project project;
  @override State<DomainsScreen> createState() => _DomainsScreenState();
}
class _DomainsScreenState extends State<DomainsScreen> with OperationState<DomainsScreen> {
  @override AppController get app => widget.app;
  List<ProjectDomain> domains = [];
  String? cursor;
  bool loaded = false;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  Future<void> _load({bool more = false}) => run(() async {
    final previous = more ? cursor : null;
    final page = await app.repository.domains(widget.project.id, cursor: previous);
    if (mounted) setState(() { domains = {for (final d in [...(more ? domains : <ProjectDomain>[]), ...page.items]) d.name: d}.values.toList();
      cursor = page.next == previous ? null : page.next; loaded = true; });
  });
  Future<void> _add() async {
    final input = await fieldsDialog(context, 'Adicionar domínio', const {'domain': 'Domínio (ex.: exemplo.com)'});
    if (!mounted || input == null) return;
    final domain = input['domain']!.trim().toLowerCase();
    if (domain.length > 253 || !RegExp(r'^(\*\.)?([a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}$').hasMatch(domain)) {
      feedback(context, 'Informe um domínio sem protocolo ou caminho. Use punycode para nomes internacionais.'); return;
    }
    if (!await confirmAction(context, title: 'Adicionar domínio?', resource: '$domain → ${widget.project.name}', production: true,
      description: 'O domínio será associado ao projeto. Pode ser necessário verificar a propriedade e configurar o DNS.')) return;
    await run(() async { await app.repository.addDomain(widget.project.id, domain);
      domains = (await app.repository.domains(widget.project.id)).items; loaded = true; }, success: 'Domínio adicionado.');
  }
  Future<void> _remove(ProjectDomain domain) async {
    if (!await confirmAction(context, title: 'Remover domínio?', resource: domain.name, destructive: true, production: true,
      description: 'Remover a associação com ${widget.project.name} pode interromper o acesso ao site.')) return;
    await run(() async { await app.repository.removeDomain(widget.project.id, domain.name); domains.removeWhere((d) => d.name == domain.name); }, success: 'Domínio removido.');
  }
  Future<void> _verify(ProjectDomain domain) async {
    if (!await confirmAction(context, title: 'Verificar domínio?', resource: domain.name, production: true,
      description: 'A Vercel verificará a propriedade usando as configurações DNS atuais.')) return;
    await run(() async { await app.repository.verifyDomain(widget.project.id, domain.name);
      final page = await app.repository.domains(widget.project.id); domains = page.items; cursor = page.next; }, success: 'Verificação solicitada.');
  }
  Future<void> _dns(ProjectDomain domain) => run(() async {
    final config = await app.repository.domainConfiguration(domain.name);
    if (!mounted) return;
    // Whitelist DNS fields instead of dumping full remote objects.
    await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text('DNS · ${domain.name}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(config['misconfigured'] == true ? 'Configuração pendente' : 'Sem pendência informada'),
        const SizedBox(height: 12), Text('Serviço: ${optionalString(config['configuredBy']) ?? 'Não informado'}'),
        for (final v in strings(config['nameservers'])) SelectableText('Nameserver: $v'),
        for (final v in strings(config['aValues'])) SelectableText('A: $v'),
        if (config['cnames'] is List) for (final v in strings(config['cnames'])) SelectableText('CNAME: $v'),
        const SizedBox(height: 12), const Text('Registros recomendados podem variar por plano e configuração. Confira o painel Vercel se a API não os informar.'),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))]));
  });
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Domínios · ${widget.project.name}'), actions: [
    IconButton(tooltip: 'Atualizar', onPressed: working ? null : () => _load(), icon: const Icon(Icons.refresh)),
    IconButton(tooltip: 'Adicionar domínio', onPressed: working ? null : _add, icon: const Icon(Icons.add))]),
    body: ListView(children: [if (working) const LinearProgressIndicator(),
      if (domains.isEmpty && !working) EmptyView(loaded ? 'Nenhum domínio associado.' : 'A consulta de domínios exige conexão com a Vercel.'),
      for (final domain in domains) ExpansionTile(title: Text(domain.name), subtitle: Text(domain.verified ? 'Verificado' : 'Verificação pendente'),
        children: [for (final verification in domain.verification) Padding(padding: const EdgeInsets.all(12),
          child: SelectableText('${optionalString(verification['type']) ?? 'DNS'} · ${optionalString(verification['domain']) ?? domain.name}\n${optionalString(verification['value']) ?? 'Valor não informado'}')),
          Wrap(spacing: 8, children: [TextButton(onPressed: working ? null : () => _dns(domain), child: const Text('Consultar DNS')),
            if (!domain.verified) TextButton(onPressed: working ? null : () => _verify(domain), child: const Text('Verificar')),
            TextButton(onPressed: working ? null : () => _remove(domain), child: const Text('Remover'))])]),
      if (cursor != null) TextButton(onPressed: working ? null : () => _load(more: true), child: const Text('Carregar mais domínios'))]));
}
