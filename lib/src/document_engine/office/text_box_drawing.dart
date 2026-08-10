/// DrawingML de uma caixa de texto CRIADA no editor (F9 — inserir).
///
/// Por que este arquivo existe. A caixa IMPORTADA é carimbada: o writer
/// devolve o `rawXml` que veio do arquivo (preservação D1), e a edição do
/// miolo troca só o `w:txbxContent` (`docx_codec._textBoxRawXml`). Uma caixa
/// criada no editor não tem rawXml nenhum — ou o writer GERA a forma inteira,
/// ou o botão "Caixa de Texto" grava um nó que desaparece no primeiro save.
/// Um botão que perde o que o usuário escreveu é pior que botão nenhum.
///
/// **Três decisões que este XML toma, e o porquê de cada uma:**
///
/// 1. **`mc:AlternateContent`, não `w:drawing` puro.** O importador só
///    reconhece caixa de texto dentro de `mc:AlternateContent`
///    (`docx/reader.dart` `_parseTextBox`, chamado no case
///    `'mc:AlternateContent'`); um `w:drawing` solto cairia em
///    `_parseDrawing` e voltaria como IMAGEM. A caixa exportada tem de
///    reabrir como caixa — inclusive no nosso próprio leitor.
///
/// 2. **Os namespaces são declarados NO elemento gerado.** O `w:document` de
///    um documento novo declara só `w` e `r`
///    (`docx/reader.dart` `createEmpty`), e um prefixo não declarado é XML
///    malformado — o diálogo de reparo do Word. Declarar localmente custa
///    alguns bytes e vale para qualquer pacote hospedeiro, importado ou não.
///
/// 3. **`wp:wrapNone` com `behindDoc="0"` — "na frente do texto".** É o que o
///    compositor REALMENTE faz com a caixa: [FloatingTextBoxLayout] é
///    desenhada em posição absoluta sobre o texto, sem exclusão (a única
///    exclusão implementada é `wrapTopAndBottom`, e ela vem do XML
///    importado). Escrever `wrapSquare` daria um arquivo que promete um
///    contorno que a tela não desenha — a divergência que o §6 do plano
///    proíbe.
///
/// O `mc:Fallback` em VML existe porque `mc:Choice Requires="wps"` é
/// ignorado por quem não entende `wps`, e sem alternativa a caixa
/// simplesmente sumiria nesses leitores. As DUAS cópias do `w:txbxContent`
/// carregam o mesmo miolo, e é por isso que
/// `docx_codec._replaceTextBoxContent` troca todas as ocorrências: atualizar
/// uma só faria o texto mudar conforme o leitor.
library;

import '../../office/ce_xml.dart';

/// EMU por twip (914400 EMU por polegada ÷ 1440 twips).
const int officeEmuPerTwip = 635;

/// Largura padrão de uma caixa nova: 10 cm × 3 cm, o mesmo tamanho com que o
/// Word cria a "Caixa de Texto Simples".
const int officeDefaultTextBoxWidthTwips = 5670;
const int officeDefaultTextBoxHeightTwips = 1701;

/// Recuos internos padrão do DrawingML: 0,1" nas laterais, 0,05" em cima e
/// embaixo. São os mesmos que a importação assume quando `wps:bodyPr` omite
/// os atributos (`docx_codec`), então caixa nova e caixa importada medem o
/// texto interno com a mesma régua.
const int officeDefaultTextBoxInsetXTwips = 144;
const int officeDefaultTextBoxInsetYTwips = 72;

/// Espessura padrão da borda: 0,5 pt, a borda fina do Word.
const int officeDefaultTextBoxBorderTwips = 10;

/// O `mc:AlternateContent` completo de uma caixa de texto nova.
///
/// [innerXml] são os blocos do miolo JÁ serializados (`<w:p>…`), porque quem
/// sabe serializar bloco é o `DocxWriter` e duplicar isso aqui criaria uma
/// segunda gramática de parágrafo.
///
/// [shapeId] tem de ser único no documento: `wp:docPr/@id` repetido é uma das
/// causas clássicas do diálogo de reparo.
String officeNewTextBoxXml({
  required String innerXml,
  required int shapeId,
  int widthTwips = officeDefaultTextBoxWidthTwips,
  int heightTwips = officeDefaultTextBoxHeightTwips,
  int insetLeftTwips = officeDefaultTextBoxInsetXTwips,
  int insetTopTwips = officeDefaultTextBoxInsetYTwips,
  int insetRightTwips = officeDefaultTextBoxInsetXTwips,
  int insetBottomTwips = officeDefaultTextBoxInsetYTwips,
  int offsetXTwips = 0,
  int offsetYTwips = 0,
  int borderWidthTwips = officeDefaultTextBoxBorderTwips,
  String? borderColor,
  String? fillColor,
  String name = 'Caixa de Texto',
}) {
  int emu(int twips) => twips * officeEmuPerTwip;
  final width = emu(widthTwips > 0 ? widthTwips : 1);
  final height = emu(heightTwips > 0 ? heightTwips : 1);
  final border = _hex(borderColor) ?? '000000';
  final fill = _hex(fillColor);
  final safeName = XmlEscape.attribute(name);

  final line = borderWidthTwips > 0
      ? '<a:ln w="${emu(borderWidthTwips)}" cmpd="sng">'
          '<a:solidFill><a:srgbClr val="$border"/></a:solidFill>'
          '</a:ln>'
      : '<a:ln><a:noFill/></a:ln>';
  final drawingFill = fill == null
      ? '<a:noFill/>'
      : '<a:solidFill><a:srgbClr val="$fill"/></a:solidFill>';

  // VML mede em PONTOS, DrawingML em EMU: a mesma caixa, duas unidades.
  String pt(int twips) => _trimZeros(twips / 20);
  final vmlFill = fill == null
      ? ' filled="f"'
      : ' fillcolor="#$fill"'; // `filled="f"` é o transparente do VML.
  final vmlStroke = borderWidthTwips > 0
      ? ' strokecolor="#$border" strokeweight="${pt(borderWidthTwips)}pt"'
      : ' stroked="f"';

  return '<mc:AlternateContent '
      'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
      'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/'
      'wordprocessingDrawing" '
      'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:wps="http://schemas.microsoft.com/office/word/2010/'
      'wordprocessingShape" '
      'xmlns:v="urn:schemas-microsoft-com:vml" '
      'xmlns:o="urn:schemas-microsoft-com:office:office">'
      '<mc:Choice Requires="wps">'
      '<w:drawing>'
      '<wp:anchor distT="0" distB="0" distL="114300" distR="114300" '
      'simplePos="0" relativeHeight="251659264" behindDoc="0" locked="0" '
      'layoutInCell="1" allowOverlap="1">'
      '<wp:simplePos x="0" y="0"/>'
      '<wp:positionH relativeFrom="column">'
      '<wp:posOffset>${emu(offsetXTwips)}</wp:posOffset>'
      '</wp:positionH>'
      '<wp:positionV relativeFrom="paragraph">'
      '<wp:posOffset>${emu(offsetYTwips)}</wp:posOffset>'
      '</wp:positionV>'
      '<wp:extent cx="$width" cy="$height"/>'
      '<wp:effectExtent l="0" t="0" r="0" b="0"/>'
      '<wp:wrapNone/>'
      '<wp:docPr id="$shapeId" name="$safeName $shapeId"/>'
      '<wp:cNvGraphicFramePr/>'
      '<a:graphic>'
      '<a:graphicData uri="http://schemas.microsoft.com/office/word/2010/'
      'wordprocessingShape">'
      '<wps:wsp>'
      '<wps:cNvSpPr txBox="1"/>'
      '<wps:spPr>'
      '<a:xfrm><a:off x="0" y="0"/><a:ext cx="$width" cy="$height"/></a:xfrm>'
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
      '$drawingFill'
      '$line'
      '</wps:spPr>'
      '<wps:txbx><w:txbxContent>$innerXml</w:txbxContent></wps:txbx>'
      '<wps:bodyPr rot="0" vert="horz" wrap="square" '
      'lIns="${emu(insetLeftTwips)}" tIns="${emu(insetTopTwips)}" '
      'rIns="${emu(insetRightTwips)}" bIns="${emu(insetBottomTwips)}" '
      'anchor="t" anchorCtr="0"><a:noAutofit/></wps:bodyPr>'
      '</wps:wsp>'
      '</a:graphicData>'
      '</a:graphic>'
      '</wp:anchor>'
      '</w:drawing>'
      '</mc:Choice>'
      '<mc:Fallback>'
      '<w:pict>'
      '<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" '
      r'path="m,l,21600r21600,l21600,xe">'
      '<v:stroke joinstyle="miter"/>'
      '<v:path gradientshapeok="t" o:connecttype="rect"/>'
      '</v:shapetype>'
      '<v:shape id="TextBox_$shapeId" type="#_x0000_t202" '
      'style="position:absolute;'
      'margin-left:${pt(offsetXTwips)}pt;margin-top:${pt(offsetYTwips)}pt;'
      'width:${pt(widthTwips)}pt;height:${pt(heightTwips)}pt;'
      'z-index:251659264;visibility:visible;mso-wrap-style:square;'
      'mso-position-horizontal-relative:column;'
      'mso-position-vertical-relative:text"$vmlFill$vmlStroke>'
      '<v:textbox inset="${pt(insetLeftTwips)}pt,${pt(insetTopTwips)}pt,'
      '${pt(insetRightTwips)}pt,${pt(insetBottomTwips)}pt">'
      '<w:txbxContent>$innerXml</w:txbxContent>'
      '</v:textbox>'
      '</v:shape>'
      '</w:pict>'
      '</mc:Fallback>'
      '</mc:AlternateContent>';
}

/// `#RRGGBB` (ou `RRGGBB`) → `RRGGBB` maiúsculo; null quando não é uma cor
/// hexadecimal de 6 dígitos — o DrawingML não tem onde guardar um `rgb()` ou
/// um nome CSS, e escrever lixo em `a:srgbClr` é reparo garantido.
String? _hex(String? value) {
  if (value == null) return null;
  final raw = value.startsWith('#') ? value.substring(1) : value;
  if (raw.length != 6) return null;
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)) return null;
  return raw.toUpperCase();
}

String _trimZeros(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
}
