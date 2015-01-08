library irrational.web.polymer.article_editor;

import 'package:irrational/irrational.dart';
import 'package:core_elements/core_collapse.dart';
import 'package:cookie/cookie.dart' as cookie;

@CustomTag('article-editor')
class ArticleEditorElement extends PolymerElement {

  ArticleEditorElement.created() : super.created() { }

  @override
  void attached() {
    super.attached();

    Duration dt = new DateTime.now().timeZoneOffset;
    String tz = "${dt.isNegative?'-':'+'}"
    + "${dt.inHours.toString().padLeft(2, '0')}:00";
    cookie.set('timezone', tz, path: '/', expires: 365);

    // show admin feature when has ?admin=true in url
    if (window.location.search.length >= 1) {
      Map query = Uri.splitQueryString(window.location.search.substring(1));
      if (query.containsKey('admin') && query['admin']=='true') {
        shadowRoot.querySelector('.admin-only').style.display = 'block';
      }
    }

    shadowRoot.querySelector('#format-help-header').onClick.listen((_) {
      (shadowRoot.querySelector('#format-help') as CoreCollapse).toggle();
    });

  }

  static Map emptyModel =
  { 'article_id' : ''
  , 'title'      : ''
  , 'content'    : ''
  , 'language'   : 'English'
  , 'tags'       : ''
  , 'source'     : ''
  , 'submitter'  : {'name': '', 'email': '', 'link': ''}
  , 'author'     : {'name': '', 'email': '', 'link': ''}
  };

  @observable Map model = toObservable(emptyModel);
  @observable String draftId = '';

  @observable String result = '';
  @observable String rejectReason = '';


  void saveArticle(Event e, var detail, Node target) {

    // TODO
    // This is used to avoid get <error-message> cancled when the target
    // get clicked. It's more like an ugly hack, it should be fixed, but
    // I haven't figured out how.
    // The same goes for other e.stopImmediatePropagation() in other funtions.
    e.stopImmediatePropagation();

    result = 'Saving article ...';
    String method = model['article_id']=='' ? 'POST' : 'PUT';
    String validateReault = validateForm(mode: 'article');
    if (validateReault != '') {
      result = validateReault;
      return;
    }

    String url = "${WSGI}/articles/${model['article_id']=='' ? '' : 'id:'+model['article_id']}";
    if (draftId!='' && draftId!=null) {
      url += '?approved_draft=${draftId}';
    }
    HttpRequest.request
    ( url
    , method: method
    , sendData: mapToPayload(model)
    ).then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      model['article_id'] = resp['article_id'];
      draftId = ''; // avoid approving multiple times
      result = method == 'POST'
      ? 'New article created.'
      : 'Article updated.';
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }


  void saveDraft(Event e, var detail, Node target) {
    e.stopImmediatePropagation();
    result = 'Saving draft ...';

    draftId = '';

    String validateReault = validateForm(mode: 'draft');
    if (validateReault != '') {
      result = validateReault;
      return;
    }

    HttpRequest.request
    ( '${WSGI}/drafts/'
    , method: 'POST'
    , sendData: mapToPayload(model)
    ).then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      draftId = resp['draft_id'];
      var temp = 'Draft accepted.';
      temp += ' You can see the review status of this draft ';
      temp += '<a href="/draft_statuses/${resp["draft_id"]}" target="_blank">here</a>';
      temp += ' later.';
      temp += '<br/><br/>Thanks for your share.';
      result = temp;
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }


  void rejectDraft(Event e, var detail, Node target) {
    e.stopImmediatePropagation();
    result = 'Rejecting draft ...';
    if (draftId=='' || rejectReason=='') {
      result = 'Draft ID/reject reason can not be empty.';
      return;
    }
    HttpRequest.request
    ( "${WSGI}/rejected_drafts/${draftId}"
    , method: 'PUT'
    , sendData: mapToPayload({'reject_reason': rejectReason})
    ).then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      result = 'Draft rejected.';
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }


  void load(Event e, var detail, Node target) {
    e.stopImmediatePropagation();
    result = 'Loading ...';

    String targetId = (target as HtmlElement).id;
    String url = '${WSGI}';

    switch (targetId) {
      case 'load-by-draft-id':
        if (draftId == '') {
          result = 'Draft ID cannot be empty.';
          return;
        }
        url += "/drafts/${draftId}"; break;
      case 'load-oldest-draft':
        url += '/drafts/oldest'; break;
      case 'load-by-article-id':
        if (model['article_id'] == '') {
          result = 'Article ID cannot be empty.';
          return;
        }
        url += "/articles/id:${model['article_id']}"; break;
      case 'load-by-article-title':
        if (model['title'] == '') {
          result = 'Article title cannot be empty.';
          return;
        }
        url += "/articles/${model['title']}"; break;
    }

    clearModel();

    HttpRequest.request(url, method: 'GET').then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      if (targetId=='load-by-draft-id' || targetId=='load-oldest-draft') {
        model = toObservable(JSON.decode(resp['content']));
        draftId = resp['draft_id'];
      } else {
        model = toObservable(resp);
      }
      result = 'Loaded.';
    }).catchError((Error error) {
      result = error.target.responseText;
    });
  }


  void clearModel([Event e, var detail, Node target]) {
    if (e != null) {
      e.stopImmediatePropagation();
    }
    model = toObservable(emptyModel);
    draftId = '';
    rejectReason = '';
    result = 'Cleared.';
  }


  String validateForm({String mode}) {
    // mode can be 'draft' or 'article'

    String validateReault = '';

    // TODO
    // Yeah, yeah, I know...
    if (model['title'] == '') {
      validateReault += '<br/><core-icon icon="error" style="color: orange;"></core-icon><span style="display: inline-block; margin-left: 0.5em;">';
      validateReault += 'Title is empty.';
      validateReault += '</span>';
    }
    if (model['content'] == '') {
      validateReault += '<br/><core-icon icon="error" style="color: orange;"></core-icon><span style="display: inline-block; margin-left: 0.5em;">';
      validateReault += 'Content is empty.';
      validateReault += '</span>';
    }

    if (mode == 'article') {
      RegExp p = new RegExp(r'^([0-9a-zA-Z]+[\w- ]*)(,[ ]*[0-9a-zA-Z]+[\w- ]*)*$');
      if (! p.hasMatch(model['tags'])) {
        validateReault += '<br/><core-icon icon="error" style="color: orange;"></core-icon><span style="display: inline-block; margin-left: 0.5em;">';
        validateReault += 'Tag format is not correct.';
        validateReault += '</span>';
      }
      if (model['submitter']['name'] == '') {
      validateReault += '<br/><core-icon icon="error" style="color: orange;"></core-icon><span style="display: inline-block; margin-left: 0.5em;">';
        validateReault += 'Submitter name is empty.';
        validateReault += '</span>';
      }
    }

    if (validateReault != '') {
      validateReault = 'There are errors in the form:<br/>${validateReault}';
    }

    return validateReault;
  }


}
