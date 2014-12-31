library irrational.web.polymer.error_message;

import 'package:irrational/irrational.dart';

@CustomTag('error-message')
class ErrorMessageElement extends PolymerElement {

  ErrorMessageElement.created() : super.created() { }

  @published String message;

  HtmlElement parent;
  HtmlElement messageElement;

  @override
  void attached() {
    parent = (this.parentNode is ShadowRoot)
    ? (this.parentNode as ShadowRoot).host
    : this.parentNode;
    messageElement = shadowRoot.querySelector('#message');

    show();

    window.onScroll.listen(hide);
    window.onClick.listen(hide);
    window.onResize.listen(show);
  }

  void show([Event e]) {
    if (message==null || message=='') {
      messageElement.style.display = 'none';
      messageElement.classes.remove('detach');
      message = '';
    } else {
      messageElement.querySelector('paper-shadow')
      .setInnerHtml(message, validator: htmlValidator);
      messageElement.style.width = 'calc(${parent.clientWidth}px - ${messageElement.getComputedStyle().paddingLeft} - ${messageElement.getComputedStyle().paddingRight})';
      messageElement.classes.add('detach');
      messageElement.style.display = 'block';
    }
  }

  void hide(Event e) {
    if (messageElement.style.display == 'none') {
      return;
    }
    bool shouldHide = false;

    if (e.type == 'scroll') {
      shouldHide = true;
    } else if (e.type == 'click') {
      if (messageElement.getBoundingClientRect().containsPoint((e as MouseEvent).client)) {
        shouldHide = false;
      } else {
        shouldHide = true;
      }
    } else {
      null;
    }

    if (shouldHide) {
      messageElement.style.display = 'none';
      messageElement.classes.remove('detach');
      message = '';
    }
  }

  messageChanged(_) {
    show();
  }


}
