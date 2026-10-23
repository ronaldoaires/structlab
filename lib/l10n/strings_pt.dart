import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/validation/validation_report.dart';

// All user-facing texts (Portuguese) for supports and loads.

// ---------------------------------------------------------------------------
// Screen: header, mode bar, properties panel
// ---------------------------------------------------------------------------

const String appName = 'StructLab';
const String appSubtitle =
    '© UnSet. Modelagem estrutural 2D para estudo e ensino.';
const String appVersion = '0.1.0';
const String appLegalese = 'Ferramenta inicial de modelagem estrutural 2D.';

const String undoTooltip = 'Desfazer';
const String moreOptionsTooltip = 'Mais opções';
const String menuNewModel = 'Novo projeto';
const String menuAbout = 'Sobre o aplicativo';

const String model2dLabel = 'MODELO 2D';
const String snapLabel = 'Snap';
const String orthoLabel = 'Ortho';
const String validateModelLabel = 'Validar modelo';

const String editTooltip = 'Editar propriedades';
const String deleteTooltip = 'Excluir elemento';

const String propsTitle = 'Propriedades';
const String propsEmpty = 'Selecione um elemento para editar seus dados.';
const String propsUnavailable = 'Dados indisponíveis';
const String propsMemberTitle = 'Barra selecionada';
const String propsSupportTitle = 'Apoio selecionado';
const String propsNodeTitle = 'Nó selecionado';
const String propsLoadTitleFallback = 'Carga selecionada';

String propsMemberSubtitle(double length, double angle) =>
    'Comp.: ${length.toStringAsFixed(2)} m · Âng.: ${angle.toStringAsFixed(1)}°';

String propsSupportSubtitle(SupportType type, int rotation) =>
    '${supportName(type)} · ${supportSideName(rotation)}';

String propsLoadTitle(LoadKind kind) => kind == LoadKind.moment
    ? 'Momento aplicado'
    : 'Carga ${loadKindName(kind).toLowerCase()}';

String propsLoadSubtitle(StructuralLoad load, String span) {
  final ang = '${load.angleDegrees.toStringAsFixed(0)}°';
  switch (load.kind) {
    case LoadKind.concentrated:
      return '${load.q1.toStringAsFixed(2)} kN · ${loadDirectionName(load.angleDegrees)}';
    case LoadKind.moment:
      return '${load.q1.abs().toStringAsFixed(2)} kN·m · ${load.q1 >= 0 ? momentCcw : momentCw}';
    case LoadKind.uniform:
      return '${load.q1.toStringAsFixed(2)} kN/m · $span · $ang';
    case LoadKind.triangular:
      final peak = load.q1 > load.q2 ? load.q1 : load.q2;
      final side = load.q2 >= load.q1 ? 'direita' : 'esquerda';
      return 'Pico ${peak.toStringAsFixed(2)} kN/m ($side) · $span · $ang';
    case LoadKind.trapezoidal:
      return '${load.q1.toStringAsFixed(2)} → ${load.q2.toStringAsFixed(2)} kN/m · $span · $ang';
  }
}

String propsNodeSubtitle(double x, double y) =>
    'X: ${x.toStringAsFixed(2)} m · Y: ${y.toStringAsFixed(2)} m';

String propsNodeDistances(double fromLeft, double fromRight) =>
    '\nDa esquerda: ${fromLeft.toStringAsFixed(2)} m · Da direita: ${fromRight.toStringAsFixed(2)} m';

String supportShortName(SupportType type) => switch (type) {
  SupportType.roller => 'Móvel',
  SupportType.pin => 'Articulado',
  SupportType.fixed => 'Engaste',
};

String supportName(SupportType type) => switch (type) {
  SupportType.roller => 'Apoio móvel',
  SupportType.pin => 'Apoio articulado',
  SupportType.fixed => 'Engaste',
};

String supportHint(SupportType type) => switch (type) {
  SupportType.roller => 'Impede só o deslocamento vertical (1 reação)',
  SupportType.pin => 'Impede deslocamento horizontal e vertical (2 reações)',
  SupportType.fixed => 'Impede deslocamentos e rotação (3 reações)',
};

String supportSideName(int rot) => switch (rot % 360) {
  0 => 'Embaixo',
  90 => 'Esquerda',
  180 => 'Em cima',
  270 => 'Direita',
  _ => '$rot°',
};

String loadKindName(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Concentrada',
  LoadKind.moment => 'Momento',
  LoadKind.uniform => 'Distribuída (retangular)',
  LoadKind.triangular => 'Triangular',
  LoadKind.trapezoidal => 'Trapezoidal',
};

String loadShortName(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Concentrada',
  LoadKind.moment => 'Momento',
  LoadKind.uniform => 'Distribuída',
  LoadKind.triangular => 'Triangular',
  LoadKind.trapezoidal => 'Trapezoidal',
};

String loadKindHint(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Força em um nó (kN)',
  LoadKind.moment => 'Momento em um nó (kN·m)',
  LoadKind.uniform => 'Mesma intensidade entre dois nós (kN/m)',
  LoadKind.triangular => 'Varia de zero até um pico (kN/m)',
  LoadKind.trapezoidal => 'Intensidade diferente em cada nó (kN/m)',
};

String loadDirectionName(double angle) {
  final a = ((angle % 360) + 360) % 360;
  if ((a - 270).abs() < 0.5) return 'de cima';
  if ((a - 90).abs() < 0.5) return 'de baixo';
  if (a < 0.5 || a > 359.5) return 'da esquerda';
  if ((a - 180).abs() < 0.5) return 'da direita';
  return '${angle.toStringAsFixed(0)}°';
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

const String cancelLabel = 'Cancelar';
const String saveLabel = 'Salvar';
const String angleLabel = 'Ângulo';
const String invalidNumberMsg = 'Digite um valor válido.';

// Member dialog
const String memberDialogTitle = 'Propriedades da barra';
const String lengthLabel = 'Comprimento';
const String memberAngleHelper = '0° = horizontal →  |  90° = vertical ↑';

// Support dialog
const String supportDialogTitle = 'Propriedades do apoio';
const String supportTypeLabel = 'Tipo';
const String supportPositionLabel = 'Posição';

// Load dialog
const String loadAngleHelper =
    'Ou digite um ângulo qualquer (−90° = de cima, para baixo).';
const String loadPeakLeft = 'Pico à esquerda';
const String loadPeakRight = 'Pico à direita';
const String loadFromTop = '↓ De cima';
const String loadFromBottom = '↑ De baixo';
const String loadFromLeft = '→ Da esquerda';
const String loadFromRight = '← Da direita';

const String memberModeAngle = 'Comprimento e ângulo';
const String memberModeRise = 'Vão e altura';
const String memberHigherSideLabel = 'Lado mais alto';
const String sideLeftLabel = 'Esquerdo';
const String sideRightLabel = 'Direito';
const String runLabel = 'Vão horizontal';
const String riseLabel = 'Altura';
const String memberRiseHelper =
    'O comprimento e o ângulo serão calculados no passo a passo.';

String loadIntensityLabel(LoadKind kind) => switch (kind) {
  LoadKind.triangular => 'Intensidade máxima (pico)',
  LoadKind.trapezoidal => 'Intensidade na esquerda',
  LoadKind.moment => 'Intensidade do momento',
  _ => 'Intensidade',
};

const String loadIntensityRightLabel = 'Intensidade na direita';

// Node distance dialog
const String nodeDialogTitle = 'Posição do nó';
const String distanceLabel = 'Distância';
const String fromLeftLabel = 'Da esquerda';
const String fromRightLabel = 'Da direita';
const String fromBottomLabel = 'De baixo';
const String fromTopLabel = 'De cima';

String nodeTotalLength(double total) =>
    'Comprimento total da barra: ${total.toStringAsFixed(2)} m';

String nodeRangeError(double lo, double hi) =>
    'O nó precisa ficar entre os nós vizinhos: de ${lo.toStringAsFixed(2)} m a ${hi.toStringAsFixed(2)} m.';

// ---------------------------------------------------------------------------
// Tools: labels, hints and messages
// ---------------------------------------------------------------------------

const String toolSelectLabel = 'Selecionar';
const String toolBeamLabel = 'Barra';
const String toolNodeLabel = 'Nó';
const String supportMenuTitle = 'Tipo de apoio';
const String loadMenuTitle = 'Tipo de carga';

// General
const String msgStart = 'Selecione uma ferramenta para começar.';
const String msgNothingToUndo = 'Não há ações para desfazer.';
const String msgUndone = 'Última ação desfeita.';
const String msgModelAlreadyEmpty = 'O modelo já está vazio.';
const String msgNewModel = 'Novo modelo criado.';
const String msgNeedBeam =
    'Desenhe pelo menos uma barra antes de validar o modelo.';
const String msgNeedSupport = 'Adicione apoios antes de analisar a estrutura.';
const String msgModelOk =
    'Modelo básico reconhecido. O motor de cálculo será implementado na próxima etapa.';
const String msgSelectToDelete = 'Selecione um elemento para excluir.';
const String msgSelectToEdit =
    'Selecione uma barra, apoio ou carga para editar.';
const String msgNodePositionByMembers =
    'A posição deste nó é definida pelas barras. Crie um nó sobre uma barra com a ferramenta Nó para controlar a distância.';
const String msgDeleted = 'Elemento excluído.';

// Select tool
const String msgSelectToolHint = 'Toque em um elemento para selecioná-lo.';
const String msgNothingSelected = 'Nenhum elemento selecionado.';
const String msgNodeSelected = 'Nó selecionado.';
const String msgSupportSelected = 'Apoio selecionado.';
const String msgLoadSelected = 'Carga selecionada.';
const String msgMemberSelected = 'Barra selecionada.';

// Beam tool
const String msgBeamToolHint =
    'Arraste (ou toque em dois pontos) para criar uma barra.';
const String msgBeamDragHint = 'Arraste até o ponto final (ou toque nele).';
const String msgBeamEndHint = 'Arraste ou toque no ponto final da barra.';
const String msgBeamZero = 'A barra precisa ter comprimento maior que zero.';
const String msgBeamDuplicate = 'Essa barra já existe.';
const String msgBeamCreated =
    'Barra criada. Toque nela e use o lápis para ajustar comprimento e ângulo.';
const String msgMemberUpdated = 'Barra atualizada.';

// Node tool
const String msgNodeToolHint =
    'Toque sobre uma barra para criar um nó. Toque em um nó para definir a distância.';
const String msgNodeTapMember = 'Toque sobre uma barra para adicionar um nó.';
const String msgNodeTooClose = 'Posição muito próxima da extremidade da barra.';
const String msgNodeExists = 'Já existe um nó nessa posição.';
const String msgNodeCreated =
    'Nó criado. Toque no lápis (ou no nó) para definir a distância exata.';

String msgNodePositioned(double d) =>
    'Nó posicionado a ${d.toStringAsFixed(2)} m da esquerda.';

// Support tool
const String msgSupportNeedNode =
    'Toque próximo a um nó existente para inserir o apoio.';
const String msgSupportExists = 'Esse nó já possui um apoio.';
const String msgSupportUpdated = 'Apoio atualizado.';

String msgSupportToolHint(SupportType t) =>
    'Toque em um nó para inserir ${supportName(t).toLowerCase()}.';

String msgSupportChosen(SupportType t) =>
    '${supportName(t)} selecionado. Toque em um nó para inserir.';

String msgSupportInserted(SupportType t) => '${supportName(t)} inserido.';

// Load tool
String loadHint(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Toque em um nó para aplicar a carga concentrada.',
  LoadKind.moment => 'Toque em um nó para aplicar o momento.',
  _ => 'Toque no nó inicial e depois no nó final da carga.',
};

const String msgLoadNeedNode =
    'Toque em um nó para aplicar a carga. Use a ferramenta Nó para criar nós sobre as barras.';
const String msgLoadFull = 'Esse nó já tem cargas concentradas nas 4 direções.';
const String msgConcentratedInserted =
    'Carga concentrada inserida. Edite o valor no lápis.';
const String msgLoadPickEnd = 'Agora toque no nó final da carga.';
const String msgLoadDifferentNode =
    'Escolha um nó diferente para o final da carga.';
const String msgLoadSameLine =
    'Os dois nós precisam estar na mesma barra reta.';
const String msgLoadOverlap =
    'Já existe uma carga distribuída nesse trecho. Duas cargas distribuídas não podem se sobrepor.';
const String msgLoadDirectionTaken =
    'Já existe uma carga concentrada nessa direção neste nó.';
const String msgLoadUpdated = 'Carga atualizada.';
const String msgMomentInserted =
    'Momento inserido. Edite o valor e o sentido no lápis.';
const String msgMomentExists = 'Esse nó já possui um momento aplicado.';
const String momentCcw = 'Anti-horário';
const String momentCw = 'Horário';

String msgDistributedInserted(LoadKind kind) =>
    'Carga ${loadKindName(kind).toLowerCase()} inserida. Edite os valores no lápis.';

const String validateShortLabel = 'Validar';
const String nodeMenuTitle = 'Tipo de nó';
const String comingSoonLabel = 'Em breve';

String nodeKindShortName(NodeKind kind) => switch (kind) {
  NodeKind.rigid => 'Nó',
  NodeKind.hinge => 'Rótula',
};

String nodeKindName(NodeKind kind) => switch (kind) {
  NodeKind.rigid => 'Nó (rígido)',
  NodeKind.hinge => 'Rótula',
};

String nodeKindHint(NodeKind kind) => switch (kind) {
  NodeKind.rigid => 'Toque sobre uma barra para criar um nó. Toque em um nó para definir a distância.',
  NodeKind.hinge => 'Rótula: libera a rotação entre barras.',
};

const String resetViewTooltip = 'Enquadrar estrutura';
const String clearTooltip = 'Limpar tela';
const String msgCleared = 'Tela limpa. Use Desfazer para recuperar.';
const String msgNodeMoved = 'Nó movido.';
const String msgNodeMoveBlocked =
    'Esse movimento desalinharia uma carga distribuída ou sobreporia outro nó.';

// ---------------------------------------------------------------------------
// Projects
// ---------------------------------------------------------------------------

const String menuProjects = 'Meus projetos';
const String projectsTitle = 'Meus projetos';
const String projectDefaultName = 'Novo projeto';
const String newProjectLabel = 'Novo projeto';
const String projectOpenLabel = 'Aberto';
const String renameLabel = 'Renomear';
const String deleteLabel = 'Excluir';
const String renameProjectTitle = 'Renomear projeto';
const String projectNameLabel = 'Nome do projeto';
const String deleteProjectTitle = 'Excluir projeto?';
const String projectsEmpty =
    'Nenhum projeto salvo ainda. Desenhe algo e ele será salvo automaticamente.';
const String msgProjectLoadFailed = 'Não foi possível abrir o projeto.';

String projectsCount(int n, int max) => '$n de $max projetos';

String projectEditedAt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Editado em ${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
}

String deleteProjectBody(String name) =>
    'O projeto "$name" será excluído permanentemente.';

String msgProjectAutoName(int n) => 'Projeto $n';

String msgProjectOpened(String name) => 'Projeto "$name" aberto.';

String msgProjectLimit(int max) =>
    'Limite de $max projetos atingido. Exclua um projeto para criar outro.';

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

const String validationOkTitle = 'Modelo pronto para calcular';
const String validationFailTitle = 'O modelo ainda não pode ser calculado';
const String validationIssuesHeader = 'PROBLEMAS ENCONTRADOS';
const String validationNextStep =
    'O motor de cálculo será a próxima etapa do app.';
const String closeLabel = 'Fechar';

String validationCounts(int errors, int warnings) {
  if (errors == 0 && warnings == 0) return 'Nenhum problema encontrado.';
  final parts = <String>[
    if (errors > 0) '$errors ${errors == 1 ? 'erro' : 'erros'}',
    if (warnings > 0) '$warnings ${warnings == 1 ? 'aviso' : 'avisos'}',
  ];
  return parts.join(' · ');
}

String staticityTitle(ValidationReport r) => switch (r.staticity) {
  Staticity.isostatic => 'Estrutura isostática',
  Staticity.hyperstatic => 'Estrutura hiperestática (grau ${r.degree})',
  Staticity.hypostatic => 'Estrutura hipostática',
  Staticity.unknown => 'Estaticidade não avaliada',
};

String staticityBody(ValidationReport r) => switch (r.staticity) {
  Staticity.isostatic =>
    'Tem ${r.reactions} reações e 3 equações de equilíbrio. A solução é única e sai só pelo equilíbrio.',
  Staticity.hyperstatic =>
    'Há ${r.degree} ${r.degree == 1 ? 'incógnita' : 'incógnitas'} a mais do que as equações de equilíbrio. Será preciso o método da rigidez (EI e EA).',
  Staticity.hypostatic => 'A estrutura não está totalmente travada: ela pode se mover como um mecanismo e não tem solução por equilíbrio.',
  Staticity.unknown =>
    'Corrija os problemas abaixo para a estrutura poder ser classificada.',
};

String issueTitle(ValidationIssue i) => switch (i.code) {
  IssueCode.noMembers => 'Nenhuma barra desenhada',
  IssueCode.noSupports => 'Estrutura sem apoios',
  IssueCode.noLoads => 'Nenhuma carga aplicada',
  IssueCode.looseNode => 'Nó solto',
  IssueCode.disconnected => 'Estrutura em ${i.args.first} partes separadas',
  IssueCode.hypostaticCount => 'Reações insuficientes',
  IssueCode.unstableGeometry => 'Apoios mal posicionados (instável)',
  IssueCode.invalidDistributedLoad => 'Carga distribuída inválida',
  IssueCode.zeroLoad => 'Carga com intensidade zero',
  IssueCode.crossingMembers => 'Barras se cruzam sem nó',
  IssueCode.nodeOnMember => 'Nó sobre uma barra sem dividi-la',
};

String issueTip(ValidationIssue i) => switch (i.code) {
  IssueCode.noMembers => 'Use a ferramenta Barra para desenhar a estrutura.',
  IssueCode.noSupports =>
    'Sem apoios a estrutura flutua. Use a ferramenta Apoio e toque em um nó.',
  IssueCode.noLoads => 'Dá para calcular, mas todos os esforços serão zero. Adicione uma carga com a ferramenta Carga.',
  IssueCode.looseNode => 'Nenhuma barra chega a este nó, então apoios e cargas nele não fazem efeito. Exclua o nó ou ligue uma barra a ele.',
  IssueCode.disconnected => 'Todas as barras precisam estar ligadas pelos nós. As barras destacadas não se conectam ao resto. Una as pontas ou redesenhe passando por um nó em comum.',
  IssueCode.hypostaticCount =>
    'Tem ${i.args.first} ${i.args.first == 1 ? 'reação' : 'reações'} e são necessárias pelo menos 3 (duas forças e um momento). Troque um apoio móvel por articulado, adicione outro apoio ou use um engaste.',
  IssueCode.unstableGeometry => 'Há reações suficientes, mas as direções delas não impedem todos os movimentos: são paralelas ou se cruzam em um único ponto. Por exemplo, só apoios verticais não seguram a estrutura na horizontal. Mude o tipo ou a posição de um apoio.',
  IssueCode.invalidDistributedLoad => 'Os dois nós da carga precisam estar na mesma reta de barras. Mova os nós de volta ou exclua a carga.',
  IssueCode.zeroLoad =>
    'Esta carga não produz efeito. Edite o valor ou exclua.',
  IssueCode.crossingMembers => 'As barras se cruzam, mas não estão ligadas entre si. O cálculo não trata esse cruzamento como uma junta.',
  IssueCode.nodeOnMember => 'O nó está em cima da barra, mas não a divide, então não há ligação. Redesenhe a barra em dois trechos terminando neste nó (a ferramenta Nó já cria o nó dividindo a barra).',
};
