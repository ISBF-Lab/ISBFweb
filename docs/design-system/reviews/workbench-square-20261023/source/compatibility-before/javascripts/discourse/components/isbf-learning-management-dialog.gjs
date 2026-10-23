import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import htmlClass from "discourse/helpers/html-class";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";

export default class ISBFLearningManagementDialog extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked error;
  @tracked lookupError;
  @tracked lookingUp = false;
  @tracked saving = false;
  @tracked selectedUser;
  @tracked studentNumber = "";
  @tracked users = null;

  data;
  #closed = false;
  #lookupGeneration = 0;

  constructor() {
    super(...arguments);
    const resource = this.args.resource;
    this.studentNumber = resource?.student_number || "";
    this.selectedUser = resource?.contributor_user_id
      ? { id: resource.contributor_user_id }
      : null;
    this.data = {
      title: resource?.title || "",
      description: resource?.description || "",
      link: resource?.links?.[0] || "",
      contributor:
        resource?.contributor ||
        this.currentUser?.name ||
        this.currentUser?.username ||
        "",
      student_number: this.studentNumber,
      course_id:
        (this.args.library ? resource?.group?.id : resource?.course?.id) ||
        this.args.course?.id,
    };
    if (this.selectedUser && this.studentNumber) {
      this.lookupUsers();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
    this.#lookupGeneration++;
  }

  get canManage() {
    return Boolean(
      this.currentUser?.admin ||
      this.currentUser?.academy_moderator_permissions?.manage_resources
    );
  }

  get collectionUrl() {
    return get(
      this.siteSettings,
      this.args.library
        ? "isbf_library_collection_form_url"
        : "isbf_learning_collection_form_url"
    );
  }

  get title() {
    return i18n(
      themePrefix(
        this.args.resource ? "isbf_v2.learning_edit" : "isbf_v2.learning_share"
      )
    );
  }

  get selectedLabel() {
    return (
      this.selectedUser?.name ||
      this.selectedUser?.username ||
      i18n(themePrefix("isbf_v2.learning_linked_user"))
    );
  }

  get associationRequired() {
    return Boolean(this.studentNumber && !this.selectedUser);
  }

  get courses() {
    return (this.args.courses || []).map((course) => ({
      ...course,
      label: i18n(themePrefix("isbf_v2.learning_course_option"), {
        grade:
          this.args.grades?.find(
            (grade) =>
              grade.id ===
              (this.args.library ? course.category_id : course.grade)
          )?.label || "",
        name: course.name,
      }),
    }));
  }

  @action
  changeStudentNumber(value, { set }) {
    set("student_number", value);
    this.studentNumber = value?.trim() || "";
    this.selectedUser = null;
    this.users = null;
    this.lookupError = null;
    this.#lookupGeneration++;
    this.lookingUp = false;
  }

  @action
  async lookupUsers() {
    if (!this.canManage || !this.studentNumber || this.saving) {
      return;
    }
    const generation = ++this.#lookupGeneration;
    this.lookingUp = true;
    this.lookupError = null;
    try {
      const response = await ajax(
        `/isbf/${this.args.library ? "library" : "learning"}/contributor-users`,
        {
          data: { student_number: this.studentNumber },
        }
      );
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.users = response.users || [];
        if (this.selectedUser) {
          this.selectedUser =
            this.users.find((user) => user.id === this.selectedUser.id) ||
            this.selectedUser;
        }
      }
    } catch {
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.lookupError = i18n(themePrefix("isbf_v2.learning_lookup_error"));
      }
    } finally {
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.lookingUp = false;
      }
    }
  }

  @action
  selectUser(user) {
    this.selectedUser = user;
  }

  @action
  close() {
    if (!this.saving) {
      this.#closed = true;
      this.args.onClose();
    }
  }

  @action
  async save(data) {
    if (
      this.#closed ||
      !this.canManage ||
      this.saving ||
      this.associationRequired
    ) {
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const payload = {
        ...data,
        student_number: this.studentNumber,
        contributor_user_id: this.selectedUser?.id || "",
      };
      if (this.args.library) {
        payload.group_id = payload.course_id;
        delete payload.course_id;
      }
      if (data.link?.trim()) {
        payload.link = data.link.trim();
      } else {
        delete payload.link;
      }
      const response = await ajax(
        `/isbf/${this.args.library ? "library" : "learning"}/resources${this.args.resource ? `/${this.args.resource.id}` : ""}`,
        {
          type: this.args.resource ? "PUT" : "POST",
          data: payload,
        }
      );
      if (response?.success !== true || response.pending !== false) {
        throw new Error("Unexpected learning management response");
      }
      if (!this.#closed) {
        this.#closed = true;
        this.args.onSubmitted(response);
      }
    } catch (error) {
      if (!this.#closed) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_edit_error"));
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }

  <template>
    {{htmlClass "isbf-learning-collection-open"}}
    <DModal
      class="isbf-learning-share-dialog isbf-learning-collection-modal"
      @closeModal={{this.close}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        {{#if this.canManage}}
          <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
            <form.Field
              @name="title"
              @title={{i18n (themePrefix "isbf_v2.learning_resource_title")}}
              @type="input"
              @validation="required"
              as |field|
            >
              <field.Control
                disabled={{this.saving}}
                maxlength={{this.siteSettings.max_topic_title_length}}
                minlength={{this.siteSettings.min_topic_title_length}}
              />
            </form.Field>
            <form.Field
              @name="description"
              @title={{i18n
                (themePrefix "isbf_v2.learning_resource_description")
              }}
              @type="textarea"
              as |field|
            >
              <field.Control disabled={{this.saving}} maxlength={{300}} />
            </form.Field>
            <form.Field
              @name="link"
              @title={{i18n (themePrefix "isbf_v2.learning_resource_link")}}
              @type="input"
              @validation={{if @resource.files.length "" "required"}}
              as |field|
            >
              <field.Control
                disabled={{this.saving}}
                maxlength={{2048}}
                @type="url"
              />
            </form.Field>
            <form.Field
              @name="contributor"
              @title={{i18n
                (themePrefix "isbf_v2.learning_resource_contributor")
              }}
              @type="input"
              as |field|
            >
              <field.Control disabled={{this.saving}} />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @name="course_id"
              @title={{i18n
                (themePrefix
                  (if
                    @library
                    "isbf_v2.library_group_name"
                    "isbf_v2.learning_course_name"
                  )
                )
              }}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control as |select|>
                {{#each this.courses as |course|}}<select.Option
                    @value={{course.id}}
                  >{{course.label}}</select.Option>{{/each}}
              </field.Control>
            </form.Field>
            <form.Field
              @name="student_number"
              @onSet={{this.changeStudentNumber}}
              @title={{i18n (themePrefix "isbf_v2.learning_student_number")}}
              @type="input"
              as |field|
            >
              <field.Control disabled={{this.saving}} maxlength={{64}} />
            </form.Field>
            <p class="isbf-learning-share-dialog__course">{{i18n
                (themePrefix "isbf_v2.learning_student_hint")
              }}</p>
            <DButton
              class="isbf-learning-share-dialog__find-user"
              @action={{this.lookupUsers}}
              @disabled={{this.lookingUp}}
              @translatedLabel={{i18n
                (themePrefix "isbf_v2.learning_find_user")
              }}
            />
            {{#if this.lookingUp}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_loading")
                }}</p>{{/if}}
            {{#each this.users as |user|}}
              <DButton
                class="isbf-learning-share-dialog__contributor-user"
                @action={{fn this.selectUser user}}
                @disabled={{this.saving}}
              >
                {{dAvatar user imageSize="small"}}
                <span>{{i18n
                    (themePrefix "isbf_v2.learning_user_option")
                    name=user.name
                    username=user.username
                  }}</span>
              </DButton>
            {{else}}
              {{#if this.users}}<p role="status">{{i18n
                    (themePrefix "isbf_v2.learning_no_user")
                  }}</p>{{/if}}
            {{/each}}
            {{#if this.selectedUser}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_selected_user")
                  user=this.selectedLabel
                }}</p>{{/if}}
            {{#if this.lookupError}}<p
                role="alert"
              >{{this.lookupError}}</p>{{/if}}
            {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
            <form.Actions>
              <DButton
                @action={{this.close}}
                @disabled={{this.saving}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
              />
              <form.Submit
                @disabled={{this.associationRequired}}
                @label={{themePrefix "isbf_v2.learning_save"}}
              />
            </form.Actions>
          </Form>
        {{else}}
          <p>{{i18n (themePrefix "isbf_v2.learning_collection_invitation")}}</p>
          <a
            class="btn btn-primary isbf-learning-share-dialog__collection-link"
            href={{this.collectionUrl}}
            rel="noopener noreferrer"
            target="_blank"
          >{{i18n (themePrefix "isbf_v2.learning_collection_open")}}</a>
        {{/if}}
      </:body>
    </DModal>
  </template>
}
