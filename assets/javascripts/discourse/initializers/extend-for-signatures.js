import { action } from "@ember/object";
import { isEmpty } from "@ember/utils";
import { withPluginApi } from "discourse/lib/plugin-api";
import RawHtml from "discourse/widgets/raw-html";

function attachSignature(api, siteSettings) {
  api.includePostAttributes("user_signature");

  api.decorateWidget("post-contents:after-cooked", (dec) => {
    const attrs = dec.attrs;
    if (isEmpty(attrs.user_signature)) {
      return;
    }

    const currentUser = api.getCurrentUser();
    let enabled;

    if (currentUser) {
      enabled =
        currentUser.get("custom_fields.see_signatures") ??
        siteSettings.signatures_visible_by_default;
    } else {
      enabled = siteSettings.signatures_visible_by_default;
    }
    if (enabled) {
      if (siteSettings.signatures_advanced_mode) {
        return [
          dec.h("hr"),
          dec.h(
            "div",
            new RawHtml({
              html: `<div class='user-signature'>${attrs.user_signature}</div>`,
            })
          ),
        ];
      } else {
        if (!attrs.user_signature.match(/^https?:\/\//)) {
          return;
        }

        try {
          const hostname = new URL(attrs.user_signature).hostname;
          const allowSet = new Set([
            "prompt.iwooji.com",
            "linux.do",
            "cdn.linux.do",
            "cdn.ldstatic.com",
            // https://github.com/zjkal/linuxdo-card
            "linux-do-card.0x1.site",
            // https://github.com/hanyu-dev/greeting-svg
            "app.acfun.win",
            "greeting.app.acfun.win",
          ]);
          if (!allowSet.has(hostname)) return;
        } catch (e) { return; }
       
        return [
          dec.h("hr"),
          dec.h("img.signature-img", {
            attributes: { src: attrs.user_signature },
          }),
        ];
      }
    }
  });
}

function addSetting(api) {
  api.modifyClass(
    "controller:preferences/profile",
    (Superclass) =>
      class extends Superclass {
        @action
        save() {
          this.set(
            "model.custom_fields.see_signatures",
            this.get("model.see_signatures")
          );
          this.get("saveAttrNames").push("custom_fields");
          super.save();
        }
      }
  );
}

export default {
  name: "extend-for-signatures",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.signatures_enabled) {
      withPluginApi("0.1", (api) => attachSignature(api, siteSettings));
      withPluginApi("0.1", (api) => addSetting(api, siteSettings));
    }
  },
};
