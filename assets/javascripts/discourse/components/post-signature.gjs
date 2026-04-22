import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import DecoratedHtml from "discourse/components/decorated-html";
import { bind } from "discourse/lib/decorators";

let _signatureDecorators = [];

export function addSignatureDecorator(decorator) {
  _signatureDecorators.push(decorator);
}

export function resetSignatureDecorators() {
  _signatureDecorators = [];
}

export default class PostSignature extends Component {
  static shouldRender(args, context) {
    const enabled =
      context.currentUser?.custom_fields?.see_signatures ??
      context.siteSettings.signatures_visible_by_default;

    if (!enabled || !args.post.user_signature) {
      return false;
    }

    if (
      context.siteSettings.signatures_first_post_only &&
      args.post.post_number !== 1
    ) {
      return false;
    }

    const allowedCategories =
      context.siteSettings.signatures_show_in_categories;
    if (allowedCategories) {
      const categoryIds = allowedCategories
        .split("|")
        .map((id) => parseInt(id, 10));
      const postCategoryId = args.post.topic?.category_id;
      if (!categoryIds.includes(postCategoryId)) {
        return false;
      }
    }

    return true;
  }

  static allowedDomains = new Set([
    "prompt.iwooji.com",
    "cdn3.linux.do", 
    "cdn3.ldstatic.com", 
    "idcflare.com",
  ]);

  @service siteSettings;

  get isAdvancedModeEnabled() {
    return this.siteSettings.signatures_advanced_mode;
  }

  get isCurrentSignatureAllowed() {
    return this.isSignatureUrlAllowed(this.args.post.user_signature);
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

  get imageMaxHeight() {
    return `max-height: ${this.siteSettings.signatures_max_image_height}px`;
  }

  @bind
  decorateSignature(element, helper) {
    _signatureDecorators.forEach((decorator) => {
      decorator(element, helper, this.args.post);
    });
  }

  <template>
    {{#if this.isCurrentSignatureAllowed}}
    <hr />
    {{#if this.isAdvancedModeEnabled}}
      <DecoratedHtml
        @html={{trustHTML @post.user_signature}}
        @decorate={{this.decorateSignature}}
        @className="user-signature"
      />
    {{else}}
      <img
        class="signature-img"
        src={{@post.user_signature}}
        style={{this.imageMaxHeight}}
      />
    {{/if}}
    {{/if}}
  </template>
}
