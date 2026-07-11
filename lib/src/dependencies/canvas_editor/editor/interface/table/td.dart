import '../../dataset/enum/table/table.dart';
import '../../dataset/enum/vertical_align.dart';
import '../element.dart';
import '../row.dart';

class ITd {
	String? conceptId;
	String? id;
	dynamic extension;
	String? externalId;
	double? x;
	double? y;
	double? width;
	double? height;
	int colspan;
	int rowspan;
	List<IElement> value;
	int? trIndex;
	int? tdIndex;
	bool? isLastRowTd;
	bool? isLastColTd;
	bool? isLastTd;
	int? rowIndex;
	int? colIndex;
	List<IRow>? rowList;
	List<IElementPosition>? positionList;
	VerticalAlign? verticalAlign;
	String? backgroundColor;
	List<TdBorder>? borderTypes;
	List<TdSlash>? slashTypes;
	double? mainHeight;
	double? realHeight;
	double? realMinHeight;
	bool? disabled;
	bool? deletable;

	/// Estado transitório do layout (F4.5/F5): identifica em qual render o
	/// `rowList` da célula foi calculado e com qual largura interna. O table
	/// paging move as MESMAS células (mesmos objetos) para as partes
	/// seguintes; sem este marcador cada divisão re-mede todas as linhas
	/// restantes → O(n²) numa tabela de milhares de linhas. Não serializado.
	int? layoutRenderId;
	double? layoutInnerWidth;

	/// Célula-continuação sintética (F4.5): inserida na parte seguinte quando
	/// um `rowspan` cruza a quebra de página (equivalente ao `vMerge continue`
	/// do Word). Removida na reconstituição da tabela (merge-back).
	bool? pagingContinuation;

	/// `rowspan` original antes de a divisão de página o truncar; usado para
	/// restaurar a célula na reconstituição. Não serializado.
	int? originalRowspan;

	ITd({
		this.conceptId,
		this.id,
		this.extension,
		this.externalId,
		this.x,
		this.y,
		this.width,
		this.height,
		required this.colspan,
		required this.rowspan,
		required this.value,
		this.trIndex,
		this.tdIndex,
		this.isLastRowTd,
		this.isLastColTd,
		this.isLastTd,
		this.rowIndex,
		this.colIndex,
		this.rowList,
		this.positionList,
		this.verticalAlign,
		this.backgroundColor,
		this.borderTypes,
		this.slashTypes,
		this.mainHeight,
		this.realHeight,
		this.realMinHeight,
		this.disabled,
		this.deletable,
		this.pagingContinuation,
		this.originalRowspan,
	});
}