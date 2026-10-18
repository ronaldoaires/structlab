import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/support.dart';

// All user-facing texts (Portuguese) for supports and loads.


// ---------------------------------------------------------------------------
// Screen: header, mode bar, properties panel
// ---------------------------------------------------------------------------

const String appName = 'StructLab';
const String appSubtitle = '© Unset. Modelagem estrutural 2D para estudo e ensino.';
const String appVersion = '0.1.0';
const String appLegalese = 'Ferramenta inicial de modelagem estrutural 2D.';

const String undoTooltip = 'Desfazer';
const String moreOptionsTooltip = 'Mais opções';
const String menuNewModel = 'Novo modelo';
const String menuAbout = 'Sobre o aplicativo';

const String model2dLabel = 'MODELO 2D';
const String snapLabel = 'Snap';
const String orthoLabel = 'Ortho';
const String unitsLabel = 'kN · m';
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

String propsLoadTitle(LoadKind kind) =>
    'Carga ${loadKindName(kind).toLowerCase()}';

String propsLoadSubtitle(StructuralLoad load, String span) {
  final ang = '${load.angleDegrees.toStringAsFixed(0)}°';
  switch (load.kind) {
    case LoadKind.concentrated:
      return '${load.q1.toStringAsFixed(2)} kN · ${loadDirectionName(load.angleDegrees)}';
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
  LoadKind.uniform => 'Distribuída (retangular)',
  LoadKind.triangular => 'Triangular',
  LoadKind.trapezoidal => 'Trapezoidal',
};

String loadShortName(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Concentrada',
  LoadKind.uniform => 'Distribuída',
  LoadKind.triangular => 'Triangular',
  LoadKind.trapezoidal => 'Trapezoidal',
};

String loadKindHint(LoadKind kind) => switch (kind) {
  LoadKind.concentrated => 'Força em um nó (kN)',
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

String loadIntensityLabel(LoadKind kind) => switch (kind) {
  LoadKind.triangular => 'Intensidade máxima (pico)',
  LoadKind.trapezoidal => 'Intensidade na esquerda',
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
String loadHint(LoadKind kind) => kind == LoadKind.concentrated
    ? 'Toque em um nó para aplicar a carga concentrada.'
    : 'Toque no nó inicial e depois no nó final da carga.';

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

String msgDistributedInserted(LoadKind kind) =>
    'Carga ${loadKindName(kind).toLowerCase()} inserida. Edite os valores no lápis.';

