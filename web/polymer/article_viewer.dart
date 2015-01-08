library irrational.web.polymer.article_viewer;

import 'package:irrational/irrational.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:paper_elements/paper_checkbox.dart';

@CustomTag('article-viewer')
class ArticleViewerElement extends PolymerElement {

  ArticleViewerElement.created() : super.created() {}

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

  @published String initial = null;

  List<PaperCheckbox> allTags = [];

  List excludes = ['00000000-0000-4000-8000-000000000000'];

  @override
  void attached() {
    super.attached();

    String title = (initial=='' || initial=='{_ title _}')
    ? null : initial;
    loadModel(null, null, null, title, true);

    window.onPopState.listen((PopStateEvent e) {
      e.preventDefault();
      String pathName = window.location.pathname;
      if (pathName.startsWith('/beautiful/')) {
        String title = pathName.substring('/beautiful/'.length);
        loadModel(null, null, null, title, false);
        // re-enable the "Next" button if disabled
        shadowRoot.querySelectorAll('paper-button[data-order="ordered"]').forEach((elem) {
          elem.attributes.remove('disabled');
          elem.querySelector('span').innerHtml = 'Next';
        });
      } else if (pathName == '/') {
        window.location.reload();
      } else {
        null;
      }
    });

    window.onResize.listen((Event e) {
      resizeVideo(e);
    });

    loadAllTags();

    shadowRoot.querySelector('#tag-collapse-header').onClick.listen((_) {
      shadowRoot.querySelector('#tag-collapse-content').toggle();
    });
  }


  void loadModel([ Event e, var detail, Node target
                 , String title=null
                 , bool pushState=true ]) {
    // Take a deep breath, this is a long function.

    // The e != null test is used to determine whether this function
    // is called manually (false) or is called by click a button (true).
    bool clicked = e!=null;

    HtmlElement button;
    if (clicked) {
      button = (target as Element).querySelector('span');
    }

    // Save button status so that I can restore it later.
    String originalStatus = clicked ? button.innerHtml : '';

    if (clicked) {
      button.innerHtml = 'Loading ...';
    }

    String url = '${WSGI}/articles/';
    if (title != null) { // get an article directly by title
      url += title;
    } else { // get current article's next
      String currentId = model['article_id'] == ''
      ? excludes[0]
      : model['article_id'];
      url += "${getEnabledTags().join(', ')}/id:${currentId}'next?";
      if (clicked && (target as Element).dataset['order']=='random') {
        url += 'order=random&excludes=${excludes.join(',')}';
      } else {
        url += 'order=newest_first';
      }
    }

    HttpRequest.request(url, method: 'GET')
    .then((HttpRequest response) {
      Map resp = JSON.decode(response.responseText);
      model = resp;

      shadowRoot.querySelector('.article-content')
      .setInnerHtml(markdownToHtml(model['content']), validator: htmlValidator);
      resizeVideo();

      excludes.add(model['article_id']);

      // Generate author or original source of this article
      String sourceInfo = '';
      if (model['author']['name'] != '') {
        sourceInfo += 'Original author is ';
        sourceInfo += model['author']['link'] != ''
        ? '<a href="${model["author"]["link"]}" target="_blank">'
        + '${model["author"]["name"]}'
        + '</a>'
        : '<span class="key-field">${model["author"]["name"]}</span>';
        sourceInfo += '. ';
      }
      if (model['source'] != '') {
        sourceInfo += 'Source is ';
        sourceInfo += '<a href="${model["source"]}" target="_blank">';
        sourceInfo += '${Uri.parse(model["source"]).host}';
        sourceInfo += '</a>';
        sourceInfo += '. ';
      }
      if (model['submitter']['name'] != '') {
        sourceInfo += 'Submitted by ';
        sourceInfo += model['submitter']['link'] != ''
        ? '<a href="${model["submitter"]["link"]}" target="_blank">'
        + '${model["submitter"]["name"]}'
        + '</a>'
        : '<span class="key-field">${model["submitter"]["name"]}</span>';
        sourceInfo += ' on ${model["submit_time"]}.';
      }
      shadowRoot.querySelector('#source-info')
      .setInnerHtml(sourceInfo, validator: htmlValidator);

      if (pushState) {
        window.history.pushState(null, model['title']
        ,'/beautiful/${model["title"].replaceAll(new RegExp(r'\ '), '_')}'.toLowerCase());
        (window.document as HtmlDocument).title = model['title'];
      }

      // restore button status
      if (clicked) {
        button.innerHtml = originalStatus;
      }
    }).catchError((Error error) {
      HttpRequest resp = error.target;
      if (resp.status == HttpStatus.NOT_FOUND && title != null) {
        window.location.href = '/404.html';
      } else if (resp.status == HttpStatus.NOT_FOUND && clicked) {
        String kind = (target as Element).dataset['order'];
        shadowRoot.querySelectorAll('paper-button[data-order="${kind}"]').forEach((elem) {
          elem.setAttribute('disabled', '');
          elem.querySelector('span').innerHtml = kind=='ordered'
          ? 'Reached Oldest'
          : 'No more';
        });
      } else if (clicked) {
        button.innerHtml = 'Error';
      } else {
        null;
      }
    });
  }


  void resizeVideo([Event e]) {
    // This will resize <iframe width= height=>, which is used by YouTube.
    int parentWidth = (this.parentNode as Element).clientWidth;
    this.shadowRoot.querySelectorAll('iframe').forEach((IFrameElement iframe) {
      String oldWidth = iframe.style.width.replaceAll('px', '');
      String oldHeight = iframe.style.height.replaceAll('px', '');
      if (oldWidth=='' || oldHeight=='') {
        oldWidth = '${iframe.width}';
        oldHeight = '${iframe.height}';
      }
      iframe.style.width = '${parentWidth}px';
      iframe.style.height = '${parentWidth ~/ (int.parse(oldWidth)/int.parse(oldHeight))}px';
    });
  }


  void loadAllTags() {

    HttpRequest.request('${WSGI}/all_tags', method: 'GET')
    .then((HttpRequest response) {
      List tags = JSON.decode(response.responseText);

      if (tags.length == 0) {
        throw('No tags found.');
      }

      String html = '';
      tags.forEach((String tag) {
        html += '''
          <span class="tag" data-selected="true">${tag}</span>
          ''';
      });
      shadowRoot.querySelector('#all-tags')
      .setInnerHtml(html, validator: htmlValidator);

      shadowRoot.querySelector('#tag-collapse-content')
      .querySelectorAll('.tag').forEach((tag) {
        allTags.add(tag);
        tag.onClick.listen((_) {
          toggleTag(tag);
        });

      });

    }).catchError((Error error) {
      HtmlElement tagCollapseContent = shadowRoot.querySelector('#tag-collapse-content');
      if (tagCollapseContent != null) {
        tagCollapseContent.innerHtml = '';
      }
    });
  }


  void reverseTags(Event e, var detail, Node target) {
    allTags.forEach((tag) => toggleTag(tag));
  }

  void toggleTag(Element tag) {
    tag.dataset['selected'] = tag.dataset['selected'] == 'true'
    ? 'false'
    : 'true';
  }

  List getEnabledTags() {
    List enabledTags = [];
    allTags.forEach((tag) {
      if (tag.dataset['selected'] == 'true') {
        enabledTags.add(tag.innerHtml.toLowerCase());
      }
    });

    if (enabledTags.length==0 || enabledTags.length==allTags.length) {
      enabledTags = ['all'];
    }

    return enabledTags;
  }

}
