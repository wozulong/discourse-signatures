import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";

export default class PostSignature extends Component {
  static shouldRender(args, context) {
    const enabled =
      context.currentUser?.custom_fields?.see_signatures ??
      context.siteSettings.signatures_visible_by_default;

    return enabled && args.post.user_signature;
  }

  static allowedDomains = new Set([
    "prompt.iwooji.com",
    "linux.do", 
    "app.acfun.win",
    "greeting.app.acfun.win",
  ]);

  @service siteSettings;

  get isAdvancedModeEnabled() {
    return this.siteSettings.signatures_advanced_mode;
  }

  isSignatureUrlAllowed(signatureUrl) {
    if (this.isAdvancedModeEnabled) {
      return true;
    }

    if (!signatureUrl.match(/^https?:\/\//)) {
      return false;
    }

    try {
      const hostname = new URL(signatureUrl).hostname;
      return this.constructor.allowedDomains.has(hostname);
    } catch (e) {
      return false;
    }
  }

  <template>
    {{#if (this.isSignatureUrlAllowed @post.user_signature)}}
    <hr />
    {{#if this.isAdvancedModeEnabled}}
      <div>
        <div class="user-signature">
          {{htmlSafe @post.user_signature}}
        </div>
      </div>
    {{else}}
      <img class="signature-img" src={{@post.user_signature}} />
    {{/if}}
    {{/if}}
  </template>
}
