
import 'package:dart_quill/src/dependencies/quill_delta_easy_parser/core/blocks/paragraph.dart';
import 'package:dart_quill/src/dependencies/quill_delta_easy_parser/core/mergers/base/merger_builder.dart';
import 'package:meta/meta.dart';

/// [NoMergeBuilder] does not accumulate nothing and return the paragraphs as are generated
@immutable
class NoMergeBuilder extends MergerBuilder {
  const NoMergeBuilder();
  @override
  List<Paragraph> buildAccumulation(List<Paragraph> paragraphs) =>
      <Paragraph>[...paragraphs];

  @override
  bool get enabled => false;

  @override
  bool canMergeBothParagraphs(
          {required Paragraph paragraph, required Paragraph nextParagraph}) =>
      false;
}
