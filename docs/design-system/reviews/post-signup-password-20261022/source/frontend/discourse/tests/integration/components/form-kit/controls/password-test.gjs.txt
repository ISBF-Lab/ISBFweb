import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import Form from "discourse/components/form";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";

module(
  "Integration | Component | FormKit | Controls | Password",
  function (hooks) {
    setupRenderingTest(hooks);

    test("default", async function (assert) {
      let data = { foo: "" };
      const mutateData = (x) => (data = x);

      await render(
        <template>
          <Form @data={{data}} @onSubmit={{mutateData}} as |form|>
            <form.Field @name="foo" @title="Foo" @type="password" as |field|>
              <field.Control />
            </form.Field>
          </Form>
        </template>
      );

      assert.form().field("foo").hasValue("");

      await formKit().field("foo").fillIn("bar");

      assert.form().field("foo").hasValue("bar");

      await formKit().submit();

      assert.deepEqual(data.foo, "bar");
    });

    test("toggle visibility", async function (assert) {
      let data = { foo: "test" };

      await render(
        <template>
          <Form @data={{data}} as |form|>
            <form.Field @name="foo" @title="Foo" @type="password" as |field|>
              <field.Control />
            </form.Field>
          </Form>
        </template>
      );

      assert
        .dom(formKit().field("foo").inputElement)
        .hasAttribute("type", "password");
      assert
        .dom(".form-kit__control-password-toggle")
        .hasAttribute(
          "title",
          i18n("login.show_password_title"),
          "the reveal action has an accessible name"
        );

      await formKit().field("foo").toggle();

      assert
        .dom(formKit().field("foo").inputElement)
        .hasAttribute("type", "text");
      assert
        .dom(".form-kit__control-password-toggle")
        .hasAttribute(
          "title",
          i18n("login.hide_password_title"),
          "the accessible name follows the visibility state"
        );
    });

    test("disabled fields also disable password visibility controls", async function (assert) {
      await render(
        <template>
          <Form as |form|>
            <form.Field
              @disabled={{true}}
              @name="password"
              @title="Password"
              @type="password"
              as |field|
            >
              <field.Control />
            </form.Field>
          </Form>
        </template>
      );
      assert
        .dom(".form-kit__control-password")
        .isDisabled("the password cannot be edited");
      assert
        .dom(".form-kit__control-password-toggle")
        .isDisabled("the visibility control respects the disabled field");
    });
  }
);
