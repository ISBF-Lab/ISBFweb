import DiscourseRecommended from "@discourse/lint-configs/eslint";
import menuImports from "./script/eslint-menu-imports.mjs";

const upstreamPlugin = DiscourseRecommended.find(
  (config) => config.plugins?.discourse
)?.plugins.discourse;
const menuPlugin = {
  ...upstreamPlugin,
  rules: {
    ...upstreamPlugin.rules,
    "ui-kit-imports": menuImports(upstreamPlugin.rules["ui-kit-imports"]),
  },
};
const recommended = DiscourseRecommended.map((config) =>
  config.plugins?.discourse
    ? { ...config, plugins: { ...config.plugins, discourse: menuPlugin } }
    : config
);

export default [
  ...recommended,
  {
    rules: {
      "ember/template-no-capital-arguments": "off",
      "ember/template-require-button-type": "off",
    },
  },
  {
    ignores: [
      "plugins/**/lib/javascripts/locale",
      "plugins/discourse-math/public",
      "public/",
      "vendor/",
      "**/node_modules/",
      "spec/",
      "frontend/discourse/dist/",
      "plugins/isbf-join/web/dist/",
      "plugins/isbf-join/web/public/",
      "plugins/isbf-join/web/shared/",
      "plugins/isbf-join/web/src/{ads,application,brand,config,gallery,main,scene}.js",
      "plugins/isbf-join/web/tests/ads.test.mjs",
      "**/*.d.ts",
      "frontend/discourse-types/external-types",
      "frontend/discourse-types/dts-generator.{js,ts}",
      "tmp/",
    ],
  },
  {
    files: ["themes/**/*.{js,gjs,ts,gts}"],
    languageOptions: {
      globals: {
        settings: "readonly",
        themePrefix: "readonly",
      },
    },
  },
  {
    languageOptions: {
      parserOptions: {
        babelOptions: {
          configFile: false,
        },
      },
    },
  },
];
