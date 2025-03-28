import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { isEmpty } from "@ember/utils";
import icon from "discourse/helpers/d-icon";
import { reload } from "discourse/helpers/page-reloader";
import { ajax } from "discourse/lib/ajax";
import {
  listColorSchemes,
  updateColorSchemeCookie,
} from "discourse/lib/color-scheme-picker";
import cookie from "discourse/lib/cookie";
import DMenu from "float-kit/components/d-menu";
import UserColorPaletteMenuItem from "./user-color-palette-menu-item";

const HORIZON_PALETTES = [
  "Horizon",
  "Marigold",
  "Violet",
  "Lily",
  "Clover",
  "Royal",
];

export default class UserColorPaletteSelector extends Component {
  @service currentUser;
  @service keyValueStore;
  @service site;
  @service session;
  @service interfaceColor;
  @tracked anonColorPaletteId = this.#loadAnonColorPalette();
  @tracked userColorPaletteId = this.session.userColorSchemeId;

  get userColorPalettes() {
    const availablePalettes = listColorSchemes(this.site)
      .map((userPalette) => {
        return {
          ...userPalette,
          accent: `#${
            userPalette.colors.find((color) => color.name === "tertiary").hex
          }`,
        };
      })
      .filter((userPalette) => {
        return HORIZON_PALETTES.some((palette) => {
          return userPalette.name.toLowerCase().includes(palette.toLowerCase());
        });
      })
      .sort();

    // Match the light scheme with the corresponding dark id based in the name
    return (
      availablePalettes
        .map((palette) => {
          if (palette.is_dark) {
            return palette;
          }

          const normalizedLightName = palette.name.toLowerCase();

          const correspondingDarkModeId = availablePalettes.find(
            (item) =>
              item.is_dark &&
              normalizedLightName ===
                item.name.toLowerCase().replace(/\s+dark$/, "")
          )?.id;

          return {
            ...palette,
            correspondingDarkModeId,
          };
        })
        // Only want to show palettes that have corresponding light/dark modes
        .filter((palette) => !palette.is_dark)
    );
  }

  get selectedColorPaletteId() {
    if (this.currentUser) {
      return this.userColorPaletteId;
    }

    return this.anonColorPaletteId;
  }

  @action
  onRegisterMenu(api) {
    this.dMenu = api;
  }

  @action
  paletteSelected(selectedPalette) {
    if (selectedPalette.id === this.selectedColorPaletteId) {
      return;
    }

    this.#updatePreference(selectedPalette);
    this.#changeSiteColorPalette(
      selectedPalette.id,
      selectedPalette.correspondingDarkModeId
    );
    this.dMenu.close();
  }

  #updatePreference(selectedPalette) {
    updateColorSchemeCookie(selectedPalette.id);
    updateColorSchemeCookie(selectedPalette.correspondingDarkModeId, {
      dark: true,
    });

    if (!this.currentUser) {
      this.anonColorPaletteId = selectedPalette.id;
    } else {
      this.userColorPaletteId = selectedPalette.id;
    }
  }

  #loadAnonColorPalette() {
    const storedAnonPaletteId = cookie("color_scheme_id");
    if (storedAnonPaletteId) {
      return parseInt(storedAnonPaletteId, 10);
    }
  }

  async #changeSiteColorPalette(lightPaletteId, darkPaletteId) {
    const lightTag = document.querySelector("link.light-scheme");
    const darkTag = document.querySelector("link.dark-scheme");

    if (!darkTag) {
      reload();
      return;
    }

    // TODO(osama) once we have built-in light/dark modes for each palette, we
    // can stop making the 2nd ajax call for the dark palette and replace it
    // with a `include_dark_scheme` param on the ajax call for the light
    // palette which will include the href for the dark palette in the response
    const lightPaletteInfo = await ajax(
      `/color-scheme-stylesheet/${lightPaletteId}.json`
    );
    const darkPaletteInfo = await ajax(
      `/color-scheme-stylesheet/${darkPaletteId}.json`
    );

    lightTag.href = lightPaletteInfo.new_href;
    darkTag.href = darkPaletteInfo.new_href;
  }

  <template>
    {{#unless (isEmpty this.userColorPalettes)}}
      <DMenu
        @identifier="user-color-palette-selector"
        @placementStrategy="fixed"
        @onRegisterApi={{this.onRegisterMenu}}
        class="btn-flat user-color-palette-selector sidebar-footer-actions-button"
        data-selected-color-palette-id={{this.selectedColorPaletteId}}
        @inline={{true}}
      >
        <:trigger>
          {{icon "paintbrush"}}
        </:trigger>
        <:content>
          <div class="user-color-palette-menu">
            <div class="user-color-palette-menu__content">
              {{#each this.userColorPalettes as |colorPalette|}}
                <UserColorPaletteMenuItem
                  @selectedColorPaletteId={{this.selectedColorPaletteId}}
                  @colorPalette={{colorPalette}}
                  @paletteSelected={{this.paletteSelected}}
                />
              {{/each}}
            </div>
          </div>
        </:content>
      </DMenu>
    {{/unless}}
  </template>
}
