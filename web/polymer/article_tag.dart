library irrational.web.polymer.article_tag;

import 'package:irrational/irrational.dart';

@CustomTag('article-tag')
class ArticleTagElement extends PolymerElement {

  ArticleTagElement.created() : super.created() { }

  @published bool checked;
  @published String tag;

  @override
  void attached() {}


}
