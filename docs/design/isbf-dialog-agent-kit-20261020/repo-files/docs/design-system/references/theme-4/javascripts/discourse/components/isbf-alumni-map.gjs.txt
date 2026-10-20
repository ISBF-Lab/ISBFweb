import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import loadScript from "discourse/lib/load-script";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { labelFontSize, visibleLabelLayers } from "../lib/alumni-map-labels";

let leafletPromise;
const COUNTRY_VIEWS = {
  CN: { center: [35, 105], zoom: 3 },
  US: { center: [39, -98], zoom: 3 },
  CA: { center: [57, -106], zoom: 3 },
  GB: { center: [55, -3], zoom: 5 },
  AU: { center: [-25, 134], zoom: 3 },
  JP: { center: [37, 138], zoom: 4 },
  DE: { center: [51, 10], zoom: 5 },
  FR: { center: [47, 2], zoom: 5 },
};

function sameOriginPath(url) {
  return typeof url === "string" && /^\/(?!\/)/.test(url) && !url.includes("\\")
    ? url
    : null;
}

function leaflet(config) {
  const script = sameOriginPath(config.leaflet_js_url);
  const stylesheet = sameOriginPath(config.leaflet_css_url);
  if (!script || !stylesheet) {
    throw new Error("Missing map assets");
  }
  if (!leafletPromise) {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = stylesheet;
    document.head.appendChild(link);
    leafletPromise = loadScript(script)
      .then(() => {
        if (!window.L) {
          throw new Error("Missing map library");
        }
        return window.L;
      })
      .catch((error) => {
        leafletPromise = null;
        link.remove();
        throw error;
      });
  }
  return leafletPromise;
}

export default class ISBFAlumniMap extends Component {
  @tracked loading = true;
  @tracked error = false;

  #element;
  #map;
  #world;
  #detail;
  #regionMarkers;
  #observer;
  #request = 0;
  #layers = new Map();

  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
    this.#observer?.disconnect();
    this.#map?.remove();
  }

  @action
  insert(element) {
    this.#element = element;
    this.initialize();
  }

  @action
  async initialize() {
    const request = ++this.#request;
    this.error = false;
    this.loading = true;
    try {
      const L = await leaflet(this.args.config);
      const data = await this.#loadLayer(this.args.config.world_map_url);
      if (request !== this.#request || this.isDestroying) {
        return;
      }
      this.#map?.remove();
      this.#map = L.map(this.#element, {
        scrollWheelZoom: false,
        attributionControl: false,
        minZoom: 1,
        maxZoom: 9,
        worldCopyJump: true,
      }).setView([35, 105], 3);
      this.#world = L.geoJSON(data, {
        style: { className: "isbf-alumni-map__country", weight: 1 },
        onEachFeature: (feature, layer) => {
          const code =
            feature.properties.country_code || feature.properties.code;
          if (code === "CN") {
            this.#bindLabel(layer, feature.properties.name);
          }
          if (this.args.config.countries.some((item) => item.code === code)) {
            layer.on("click", () => this.args.onSelect({ country: code }));
          }
        },
      }).addTo(this.#map);
      this.#map.on("zoomend moveend", () => this.#refreshLabels());
      this.#observer?.disconnect();
      this.#observer = new ResizeObserver(() => this.#map?.invalidateSize());
      this.#observer.observe(this.#element);
      this.loading = false;
      await this.updateSelection();
    } catch {
      if (request === this.#request && !this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (request === this.#request && !this.isDestroying) {
        this.loading = false;
      }
    }
  }

  @action
  returnToChina() {
    if (this.args.country === "CN" && !this.args.region) {
      this.updateSelection();
    } else {
      this.args.onSelect({ country: "CN" });
    }
  }

  @action
  async updateSelection() {
    if (!this.#map) {
      return;
    }
    const request = ++this.#request;
    this.#detail?.remove();
    this.#regionMarkers?.remove();
    this.#detail = null;
    this.#regionMarkers = null;
    this.error = false;
    const country = this.args.country;
    const region = this.args.region;
    let countryLayer;
    this.#world.eachLayer((layer) => {
      const code =
        layer.feature.properties.country_code || layer.feature.properties.code;
      layer.setStyle({
        className: "isbf-alumni-map__country",
        fillOpacity: code === country ? 0.45 : 0.15,
      });
      if (code === country) {
        countryLayer = layer;
      }
    });
    const view = COUNTRY_VIEWS[country];
    if (view) {
      this.#map.setView(view.center, view.zoom);
    } else if (countryLayer) {
      this.#map.fitBounds(countryLayer.getBounds(), {
        padding: [20, 20],
        maxZoom: 4,
      });
    } else if (!country) {
      this.#map.setView([20, 0], 1);
    }
    const url = country === "CN" ? this.args.config.region_map_urls?.CN : null;
    if (!url) {
      this.#refreshLabels();
      return;
    }
    try {
      const data = await this.#loadLayer(url);
      if (request !== this.#request || this.isDestroying) {
        return;
      }
      const L = window.L;
      this.#detail = L.geoJSON(data, {
        style: (feature) => ({
          className: "isbf-alumni-map__region",
          weight: 1,
          fillOpacity: feature.properties.code === region ? 0.55 : 0.2,
        }),
        onEachFeature: (feature, layer) => {
          this.#bindLabel(layer, feature.properties.name);
          layer.on("click", () =>
            this.args.onSelect({ country, region: feature.properties.code }),
          );
          if (feature.properties.code === region) {
            this.#map.fitBounds(layer.getBounds(), {
              padding: [20, 20],
              maxZoom: 6,
            });
          }
        },
      }).addTo(this.#map);
      const regions =
        this.args.config.countries.find((item) => item.code === country)
          ?.regions || [];
      const boundaries = new Set(
        data.features.map((feature) => feature.properties.code),
      );
      this.#regionMarkers = L.layerGroup(
        regions
          .filter(
            (item) =>
              !boundaries.has(item.code) &&
              Number.isFinite(item.center?.lat) &&
              Number.isFinite(item.center?.lng),
          )
          .map((item) => {
            const marker = L.circleMarker([item.center.lat, item.center.lng], {
              radius: item.code === region ? 7 : 5,
              className: "isbf-alumni-map__region",
              regionCode: item.code,
            });
            this.#bindLabel(marker, item.name);
            marker.on("click", () =>
              this.args.onSelect({ country, region: item.code }),
            );
            if (item.code === region) {
              this.#map.setView([item.center.lat, item.center.lng], 7);
            }
            return marker;
          }),
      ).addTo(this.#map);
      this.#refreshLabels();
    } catch {
      if (request === this.#request && !this.isDestroying) {
        this.error = true;
      }
    }
  }

  #bindLabel(layer, name) {
    layer.bindTooltip(this.#label(name), {
      className: "isbf-alumni-map__china-label",
      direction: "center",
      permanent: false,
    });
    layer.on("mouseout", () => this.#refreshLabels());
  }

  #refreshLabels() {
    if (!this.#map) {
      return;
    }
    const zoom = this.#map.getZoom();
    const fontSize = labelFontSize(zoom);
    this.#element.style.setProperty(
      "--isbf-alumni-label-size",
      `${fontSize}px`,
    );
    this.#world?.eachLayer((layer) => layer.closeTooltip());
    const candidates = [];
    const bounds = this.#map.getBounds();
    const context = document.createElement("canvas").getContext("2d");
    context.font = `${fontSize}px sans-serif`;
    const collect = (layer) => {
      layer.closeTooltip();
      if (zoom < 4) {
        return;
      }
      const center = layer.getLatLng?.() || layer.getCenter();
      if (!bounds.contains(center)) {
        return;
      }
      const point = this.#map.latLngToContainerPoint(center);
      const name = layer.getTooltip().getContent().textContent;
      const width = context.measureText(name).width + 10;
      const height = fontSize * 1.25 + 6;
      candidates.push({
        layer,
        selected:
          (layer.feature?.properties.code || layer.options.regionCode) ===
          this.args.region,
        box: {
          left: point.x - width / 2,
          right: point.x + width / 2,
          top: point.y - height / 2,
          bottom: point.y + height / 2,
        },
      });
    };
    this.#detail?.eachLayer(collect);
    this.#regionMarkers?.eachLayer(collect);
    visibleLabelLayers(candidates, this.#map.getSize()).forEach((layer) =>
      layer.openTooltip(),
    );
  }

  #label(name) {
    const label = document.createElement("span");
    label.textContent = name || "";
    return label;
  }

  async #loadLayer(url) {
    const path = sameOriginPath(url);
    if (!path) {
      throw new Error("Invalid map asset");
    }
    if (!this.#layers.has(path)) {
      this.#layers.set(
        path,
        ajax(path).catch((error) => {
          this.#layers.delete(path);
          throw error;
        }),
      );
    }
    return this.#layers.get(path);
  }

  <template>
    <div class="isbf-alumni-map">
      <DButton
        class="btn-flat isbf-alumni-map__reset"
        @action={{this.returnToChina}}
        @translatedLabel={{i18n (themePrefix "isbf_v2.alumni_return_china")}}
      />
      <div
        aria-label={{i18n (themePrefix "isbf_v2.alumni_map")}}
        class="isbf-alumni-map__canvas"
        {{didInsert this.insert}}
        {{didUpdate this.updateSelection @country @region}}
      ></div>
      {{#if this.loading}}<p role="status">{{i18n
            (themePrefix "isbf_v2.learning_loading")
          }}</p>{{/if}}
      {{#if this.error}}<p role="alert">{{i18n
            (themePrefix "isbf_v2.alumni_map_error")
          }}</p><DButton
          @action={{this.initialize}}
          @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
        />{{/if}}
      <small class="isbf-alumni-map__credit">Natural Earth · Leaflet</small>
    </div>
  </template>
}
