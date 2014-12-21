library beauty.web.polymer.article_viewer;

import 'package:beauty/beauty.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

@CustomTag('article-viewer')
class ArticleViewerElement extends PolymerElement {

  ArticleViewerElement.created() : super.created() { }

  @observable Map model = toObservable(
    { 'article_id'  : ''
    , 'title'       : ''
    , 'content'     : ''
    , 'language'    : ''
    , 'tags'        : ''
    , 'submit_time' : ''
    , 'source'      : ''
    , 'submitter'   : {'name': '', 'email': '', 'link': ''}
    , 'author'      : {'name': '', 'email': '', 'link': ''}
    });

  @override
  void attached() {
    super.attached();

    // If there is ?article=<title> in url, load this article,
    // else load the latest one.
    String queryString = window.location.search.startsWith('?')
    ? window.location.search.substring(1)
    : window.location.search;
    Map query = Uri.splitQueryString(queryString);
    String title = query.containsKey('article') ? query['article'] : null;
    loadModel(null, null, null, title);

    window.onPopState.listen((PopStateEvent e) {
      if (window.location.pathname.startsWith('/index.html') ||
          window.location.pathname == '/' ) {
        // pass
      } else {
        window.history.go(0);
      }
    });
  }

  String excludes = '00000000-0000-0000-0000-000000000000';

  void loadModel([Event e, var detail, Node target, String title=null]) {
    // The e != null test is used to determine whether this function
    // is called manually or is called by click a button.

    String originalStatus = e!=null ? target.innerHtml : '';
    if (e != null) {
      target.innerHtml = 'Loading ...';
    }

    String url = '${WSGI}/articles/';
    if (title != null) {
      url += title;
    } else {
      String currentId = model['article_id'] == ''
                       ? '00000000-0000-0000-0000-000000000000'
                       : model['article_id'];
      url += "all/id:${currentId}'next?";
      if (e!=null && target.dataset['order']=='random') {
        url += 'order=random&excludes=${excludes}';
      } else {
        url += 'order=oldest_first';
      }
    }

    HttpRequest.request(url, method: 'GET')
    .then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      model = resp;
      shadowRoot.querySelector('#article-content')
      .setInnerHtml(markdownToHtml(model['content']), validator: htmlValidator);
      excludes += ',${model['article_id']}';

      // generate author or original source of this article
      String sourceInfo = '';
      if (model['author']['name'] != '') {
        sourceInfo += 'Author is ';
        sourceInfo += model['author']['link'] != ''
        ? '<a href="${model["author"]["link"]}" target="_blank">'
        + '${model["author"]["name"]}'
        + '</a>'
        : '${model["author"]["name"]}';
      } else {
        sourceInfo += 'Source is ';
        sourceInfo += '<a href="${model["source"]}" target="_blank">';
        sourceInfo += '${Uri.parse(model["source"]).host}';
        sourceInfo += '</a>';
      }
      sourceInfo += ', submitted on ${model["submit_time"]}.';
      shadowRoot.querySelector('#source-info')
      .setInnerHtml(sourceInfo, validator: htmlValidator);

      if (title != null) {
        window.history.replaceState(null, model['title']
        ,'/articles/${model["title"].replaceAll(new RegExp(r'\ '), '_')}'.toLowerCase());
      } else {
        window.history.pushState(null, model['title']
        ,'/articles/${model["title"].replaceAll(new RegExp(r'\ '), '_')}'.toLowerCase());
      }
      window.document.title = model['title'];

      if (e != null) {
        target.innerHtml = originalStatus;
      }
    }).catchError((Error error) {
      if (e != null) {
        target.innerHtml = error.target.responseText;
      }
      if (error.target is HttpRequest) {
        HttpRequest resp = error.target;
        if (resp.status == HttpStatus.NOT_FOUND && title != null) {
          window.location.href = 'http://${FQDN}/404.html';
        }
      }
    });
  }

}
