import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import { reload } from "discourse/helpers/page-reloader";
import {
  loadColorSchemeStylesheet,
  updateColorSchemeCookie,
} from "discourse/lib/color-scheme-picker";

export default class SitePaletteMenuItem extends Component {
  @service site;
  @service session;
  @service interfaceColor;

  get siteStyle() {
    return `--icon-color: ${this.args.colorPalette.accent}`;
  }

  @action
  handleInput() {
    console.log(this.args.colorPalette);

    if (this.interfaceColor.lightModeForced) {
      loadColorSchemeStylesheet(this.args.colorPalette.id);
      updateColorSchemeCookie(this.args.colorPalette.id);
      updateColorSchemeCookie(this.args.colorPalette.correspondingDarkModeId, {
        dark: true,
      });
    } else if (this.interfaceColor.darkModeForced) {
      loadColorSchemeStylesheet(this.args.colorPalette.correspondingDarkModeId);
      updateColorSchemeCookie(this.args.colorPalette.id);
      updateColorSchemeCookie(this.args.colorPalette.correspondingDarkModeId, {
        dark: true,
      });
    }
    reload();
  }

  <template>
    <div class="color-palette-menu__item" data-color="color-palette-name">
      <DButton
        class={{concatClass "btn-flat color-palette-menu__item-choice"}}
        style={{htmlSafe this.siteStyle}}
        @icon="circle"
        @translatedLabel={{@colorPalette.name}}
        @action={{this.handleInput}}
      />
    </div>
  </template>
}
