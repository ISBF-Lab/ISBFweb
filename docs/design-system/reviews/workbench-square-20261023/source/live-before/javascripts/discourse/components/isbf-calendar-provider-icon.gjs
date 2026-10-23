import Component from "@glimmer/component";

export default class ISBFCalendarProviderIcon extends Component {
  get isApple() {
    return this.args.provider === "apple";
  }

  get isGoogle() {
    return this.args.provider === "google";
  }

  get isOutlook() {
    return this.args.provider === "outlook";
  }

  <template>
    <svg
      aria-hidden="true"
      class="isbf-calendar-provider-icon"
      fill="none"
      focusable="false"
      height="20"
      viewBox="0 0 24 24"
      width="20"
    >
      {{#if this.isApple}}
        <path
          d="M17.05 12.54c.03 3.05 2.68 4.07 2.71 4.08-.02.07-.42 1.45-1.39 2.87-.84 1.23-1.71 2.45-3.08 2.48-1.34.03-1.78-.8-3.31-.8-1.54 0-2.02.77-3.29.83-1.32.05-2.33-1.33-3.18-2.56-1.73-2.5-3.05-7.07-1.28-10.15a4.94 4.94 0 0 1 4.18-2.54c1.31-.03 2.55.88 3.35.88.8 0 2.3-1.09 3.88-.93.66.03 2.5.27 3.68 2-.1.06-2.2 1.28-2.17 3.84ZM14.52 5.04c.7-.85 1.18-2.02 1.05-3.19-1.01.04-2.24.67-2.96 1.51-.65.75-1.22 1.95-1.07 3.09 1.13.09 2.28-.57 2.98-1.41Z"
          fill="currentColor"
        />
      {{else if this.isGoogle}}
        <path
          d="M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.6 4.6 0 0 1-2 3.02v2.51h3.25c1.9-1.75 2.97-4.33 2.97-7.36Z"
          fill="#4285f4"
        />
        <path
          d="M12 22c2.7 0 4.96-.9 6.62-2.41l-3.25-2.51c-.9.6-2.05.97-3.37.97-2.61 0-4.82-1.76-5.61-4.12H3.03v2.59A10 10 0 0 0 12 22Z"
          fill="#34a853"
        />
        <path
          d="M6.39 13.93a6.02 6.02 0 0 1 0-3.86V7.48H3.03a10 10 0 0 0 0 9.04l3.36-2.59Z"
          fill="#fbbc05"
        />
        <path
          d="M12 5.95c1.47 0 2.79.51 3.82 1.51l2.87-2.87A9.61 9.61 0 0 0 12 2a10 10 0 0 0-8.97 5.48l3.36 2.59C7.18 7.71 9.39 5.95 12 5.95Z"
          fill="#ea4335"
        />
      {{else if this.isOutlook}}
        <rect fill="#0078d4" height="17" rx="1.5" width="13" x="8" y="3" />
        <path d="M8 8h13v12H8Z" fill="#28a8ea" />
        <path
          d="m8 10 7 5 7-5v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1Z"
          fill="#1490df"
        />
        <path d="m8 10 7 5 7-5" stroke="#b3e1fa" stroke-width="1.2" />
        <rect fill="#0a5aa7" height="14" rx="1" width="12" x="1" y="6" />
        <path
          d="M7 9c-2.15 0-3.5 1.54-3.5 4s1.35 4 3.5 4 3.5-1.54 3.5-4S9.15 9 7 9Zm0 1.6c1.15 0 1.8.88 1.8 2.4s-.65 2.4-1.8 2.4-1.8-.88-1.8-2.4.65-2.4 1.8-2.4Z"
          fill="white"
          fill-rule="evenodd"
        />
      {{else}}
        <path
          d="m10 13 4-4m-6.5 2.5-2 2a4.24 4.24 0 0 0 6 6l2-2m-3-11 2-2a4.24 4.24 0 0 1 6 6l-2 2"
          stroke="currentColor"
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
        />
      {{/if}}
    </svg>
  </template>
}
