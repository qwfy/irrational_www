library beauty.web.polymer.article_editor;

import 'package:beauty/beauty.dart';

@CustomTag('article-editor')
class ArticleEditorElement extends PolymerElement {

  ArticleEditorElement.created() : super.created() { }

  @observable Map model = toObservable(
    { 'article_id' : ''
    , 'title'      : ''
    , 'content'    : ''
    , 'language'   : 'English'
    , 'tags'       : ''
    , 'source'     : ''
    , 'submitter'  : {'name': 'Admin', 'email': '', 'link': ''}
    , 'author'     : {'name': '', 'email': '', 'link': ''}
    });

  @observable String result = 'Ready to operate.';

  void save(Event e, var detail, Node target) {
    result = 'Saving article.';
    HttpRequest.request(
      "${WSGI}/articles/${model['article_id']=='' ? '' : 'id:'+model['article_id']}",
      method: model['article_id']=='' ? 'POST' : 'PUT',
      sendData: mapToForm({'json_payload': JSON.encode(model)})
    ).then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      result = '${response.status} ${response.statusText}: ${resp["error_text"]}';
      model['article_id'] = resp['article_id'];
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }

  void loadModel(Event e, var detail, Node target) {
    result = 'Loading article.';

    if (model['article'] == '') {
      result = 'Need Article ID.';
      return null;
    }

    HttpRequest.request(
      "${WSGI}/articles/${model['article_id']=='' ? model['title'] : 'id:'+model['article_id']}",
      method: 'GET'
    ).then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      result = '${response.status} ${response.statusText}: ${resp["error_text"]}';
      model = resp;
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }
  void clear(Event e, var detail, Node target) {
    model = toObservable(
            { 'article_id' : ''
            , 'title'      : ''
            , 'content'    : ''
            , 'language'   : 'English'
            , 'tags'       : ''
            , 'source'     : ''
            , 'submitter'  : {'name': 'Admin', 'email': '', 'link': ''}
            , 'author'     : {'name': '', 'email': '', 'link': ''}
            });
    result = 'Cleared.';
  }

}
