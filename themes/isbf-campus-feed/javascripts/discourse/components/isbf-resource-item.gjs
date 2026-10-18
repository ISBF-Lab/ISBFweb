import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";
import { isImageAttachment } from "../lib/content-images";
import {
  learningEditableResource,
  learningFileSize,
  learningSafeUrl,
} from "../lib/learning-resources";
import contentImages from "../modifiers/content-images";

export default class ISBFResourceItem extends Component {
  @service currentUser;
  @service dialog;
  @service site;

  @tracked deleteError = null;
  @tracked deleting = false;
  @tracked menuPending = false;

  menuTriggers = ["click"];

  #closed = false;
  #hoverOpened = false;
  #menu;
  #opening = false;
  #pointerType;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
    this.#menu = null;
  }

  get config() {
    return this.args.library
      ? this.site?.isbf_library
      : this.site?.isbf_learning;
  }

  get canDelete() {
    return Boolean(
      (this.currentUser?.admin ||
        (!this.args.library &&
          this.currentUser?.academy_moderator_permissions?.manage_resources)) &&
      this.config?.resource_admin_management === true &&
      this.args.resource.can_delete === true
    );
  }

  get canEdit() {
    return this.canDelete && learningEditableResource(this.args.resource);
  }

  get contributor() {
    return (
      this.args.resource.contributor ||
      this.args.resource.author?.name ||
      this.args.resource.author?.username ||
      i18n(themePrefix("isbf_v2.learning_unknown_contributor"))
    );
  }

  get menuIdentifier() {
    return `isbf-learning-resource-more-${this.args.resource.id}`;
  }

  get createdAtLabel() {
    const date = new Date(this.args.resource.created_at);
    return Number.isNaN(date.getTime())
      ? ""
      : new Intl.DateTimeFormat(undefined, {
          dateStyle: "medium",
        }).format(date);
  }

  get files() {
    return (this.args.resource.files || []).flatMap((file) => {
      const url = learningSafeUrl(file.url);
      return url
        ? [
            {
              ...file,
              url,
              sizeLabel: learningFileSize(file.size),
              isImage: isImageAttachment(file),
            },
          ]
        : [];
    });
  }

  get gradeLabel() {
    return (this.args.grades || []).find(
      (grade) => grade.id === this.args.resource.grade
    )?.label;
  }

  get links() {
    return (this.args.resource.links || []).filter((value) => {
      if (!learningSafeUrl(value) || !/^https?:\/\//i.test(value)) {
        return false;
      }
      try {
        const url = new URL(value);
        return Boolean(url.hostname && !url.username && !url.password);
      } catch {
        return false;
      }
    });
  }

  get titleUrl() {
    return this.links[0];
  }

  get additionalLinks() {
    return this.args.resource.link_only ? [] : this.links;
  }

  @action
  registerMenu(menu) {
    this.#menu = menu;
  }

  @action
  rememberPointer(event) {
    this.#pointerType = event.pointerType;
  }

  @action
  pinHoveredMenu(event) {
    if (
      this.#hoverOpened &&
      this.#menu?.expanded &&
      this.#pointerType === "mouse" &&
      event.detail !== 0
    ) {
      this.#hoverOpened = false;
      event.stopImmediatePropagation();
      event.stopPropagation();
    }
  }

  @action
  async showForMouse(event) {
    if (
      event.pointerType !== "mouse" ||
      this.#closed ||
      this.isDestroying ||
      this.deleting ||
      this.menuPending ||
      !this.canDelete ||
      !this.#menu ||
      this.#menu.expanded ||
      this.#opening
    ) {
      return;
    }
    this.#opening = true;
    this.#hoverOpened = true;
    try {
      await this.#menu.show();
    } finally {
      this.#opening = false;
    }
  }

  @action
  async editFromMenu(menu) {
    if (
      this.#closed ||
      this.isDestroying ||
      this.menuPending ||
      this.deleting ||
      !this.canEdit
    ) {
      return;
    }
    this.menuPending = true;
    try {
      await menu.close();
      if (!this.#closed && !this.isDestroying && this.canEdit) {
        this.args.onEdit(this.args.resource);
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.menuPending = false;
      }
    }
  }

  @action
  async deleteFromMenu(menu) {
    if (
      this.#closed ||
      this.isDestroying ||
      this.menuPending ||
      this.deleting ||
      !this.canDelete
    ) {
      return;
    }
    this.menuPending = true;
    try {
      await menu.close();
      await this.deleteResource();
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.menuPending = false;
      }
    }
  }

  @action
  async deleteResource() {
    if (this.#closed || this.isDestroying || this.deleting || !this.canDelete) {
      return;
    }
    this.deleting = true;
    this.deleteError = null;
    try {
      const confirmed = await this.dialog.confirm({
        message: i18n(
          themePrefix(
            this.args.library
              ? "isbf_v2.library_delete_confirm"
              : "isbf_v2.learning_delete_confirm"
          )
        ),
        confirmButtonLabel: themePrefix("isbf_v2.learning_delete"),
      });
      if (!confirmed || this.#closed || this.isDestroying || !this.canDelete) {
        return;
      }
      const response = await ajax(
        `/isbf/${this.args.library ? "library" : "learning"}/resources/${encodeURIComponent(this.args.resource.id)}`,
        { type: "DELETE" }
      );
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (response?.success !== true) {
        throw new Error("Unexpected learning delete response");
      }
      this.#closed = true;
      this.args.onDeleted();
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.deleteError =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_delete_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.deleting = false;
      }
    }
  }

  <template>
    <article class="isbf-learning-resource">
      <div class="isbf-learning-resource__header">
        <h3>{{#if this.titleUrl}}<a
              href={{this.titleUrl}}
              rel="noopener noreferrer"
              target="_blank"
            >{{@resource.title}}</a>{{else}}{{@resource.title}}{{/if}}</h3>
        <div class="isbf-learning-resource__metadata">
          <time datetime={{@resource.created_at}}>{{this.createdAtLabel}}</time>
          {{#if this.canDelete}}
            <DMenu
              @ariaLabel={{i18n "more"}}
              @autofocus={{false}}
              @contentClass="isbf-learning-resource-menu"
              @disabled={{this.deleting}}
              @icon="ellipsis"
              @identifier={{this.menuIdentifier}}
              @interactive={{true}}
              @modalForMobile={{false}}
              @onRegisterApi={{this.registerMenu}}
              @placement="bottom-end"
              @title={{i18n "more"}}
              @triggerClass="btn-flat isbf-learning-resource__more"
              @triggers={{this.menuTriggers}}
              @untriggers={{this.menuTriggers}}
              {{on "pointerenter" this.showForMouse}}
              {{on "pointerup" this.rememberPointer}}
              {{on "click" this.pinHoveredMenu capture=true}}
            >
              <:content as |menu|>
                <DDropdownMenu as |dropdown|>
                  {{#if this.canEdit}}
                    <dropdown.item>
                      <DButton
                        class="btn-flat isbf-learning-resource__edit"
                        @action={{fn this.editFromMenu menu}}
                        @disabled={{this.menuPending}}
                        @translatedLabel={{i18n
                          (themePrefix "isbf_v2.learning_edit")
                        }}
                      />
                    </dropdown.item>
                  {{/if}}
                  <dropdown.item>
                    <DButton
                      class="btn-flat isbf-learning-resource__delete"
                      @action={{fn this.deleteFromMenu menu}}
                      @disabled={{this.menuPending}}
                      @translatedLabel={{i18n
                        (themePrefix "isbf_v2.learning_delete")
                      }}
                    />
                  </dropdown.item>
                </DDropdownMenu>
              </:content>
            </DMenu>
          {{/if}}
        </div>
      </div>
      {{#if @resource.description}}<p
          class="isbf-learning-resource__description"
        >{{@resource.description}}</p>{{/if}}
      {{#if @searching}}<p class="isbf-learning-resource__context">{{#if
            @library
          }}{{@resource.category.name}}
            ·
            {{@resource.group.name}}{{else}}{{this.gradeLabel}}
            ·
            {{@resource.course.name}}{{/if}}</p>{{/if}}
      {{#if this.deleteError}}<p
          class="isbf-learning-resource__error"
          role="alert"
        >{{this.deleteError}}</p>{{/if}}
      {{#if this.files.length}}
        <ul
          aria-label={{i18n (themePrefix "isbf_v2.learning_files")}}
          class="isbf-learning-resource__attachments"
          {{contentImages}}
        >
          {{#each this.files as |file|}}
            <li>
              <a href={{file.url}}>{{file.name}}</a>
              <span>{{file.sizeLabel}}</span>
              {{#if file.isImage}}
                <a
                  aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
                  class="lightbox isbf-content-image-attachment"
                  href={{file.url}}
                >{{i18n (themePrefix "isbf_v2.preview_image")}}</a>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{/if}}
      {{#if this.additionalLinks.length}}
        <ul
          aria-label={{i18n (themePrefix "isbf_v2.learning_links")}}
          class="isbf-learning-resource__attachments"
        >
          {{#each this.additionalLinks as |url|}}<li><a
                href={{url}}
                rel="noopener noreferrer"
                target="_blank"
              >{{url}}</a></li>{{/each}}
        </ul>
      {{/if}}
      <p class="isbf-learning-resource__credit"><span>{{i18n
            (themePrefix "isbf_v2.learning_contributor_credit")
          }}</span>{{this.contributor}}</p>
    </article>
  </template>
}
