import { config } from './config.js';
import { validateApplication } from '../shared/application.js';
import { submitApplication } from './application-transport.js';

export function createApplicationDialog() {
  const dialog = document.querySelector('#contact-dialog');
  const form = document.querySelector('#application-form');
  const fieldset = document.querySelector('#application-fields');
  const submit = document.querySelector('#application-submit');
  const submitContent = [...submit.childNodes].map((node) => node.cloneNode(true));
  const success = document.querySelector('#application-success');
  const error = document.querySelector('#application-error');
  const fieldIds = { name: 'application-name', studentId: 'application-student-id', phone: 'application-phone' };
  const errorIds = { name: 'name-error', studentId: 'student-id-error', phone: 'phone-error' };
  const emailLink = document.querySelector('#recruitment-email');
  emailLink.firstChild.textContent = `${config.recruitment.email} `;
  emailLink.href = `mailto:${config.recruitment.email}`;
  let state = 'idle';
  let submissionId = crypto.randomUUID();

  const setErrors = (errors = {}) => {
    for (const key of Object.keys(fieldIds)) {
      const input = document.getElementById(fieldIds[key]);
      const message = document.getElementById(errorIds[key]);
      input.setAttribute('aria-invalid', String(Boolean(errors[key])));
      message.hidden = !errors[key];
      message.textContent = errors[key] || '';
    }
  };
  const setState = (next) => { state = next; dialog.dataset.state = next; };
  document.querySelector('#contact-button').addEventListener('click', () => {
    if (state === 'success') {
      form.hidden = false;
      success.hidden = true;
      submissionId = crypto.randomUUID();
      setState('idle');
    }
    document.body.classList.add('has-dialog');
    dialog.showModal();
  });
  dialog.querySelectorAll('#dialog-close, [data-dialog-close]').forEach((button) => button.addEventListener('click', () => dialog.close()));
  dialog.addEventListener('close', () => document.body.classList.remove('has-dialog'));
  dialog.addEventListener('click', (event) => { if (event.target === dialog) dialog.close(); });
  form.addEventListener('input', (event) => {
    const key = event.target.name;
    if (!fieldIds[key]) return;
    event.target.setAttribute('aria-invalid', 'false');
    document.getElementById(errorIds[key]).hidden = true;
    error.hidden = true;
  });
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (state === 'submitting') return;
    const result = validateApplication(Object.fromEntries(new FormData(form)));
    setErrors(result.errors);
    error.hidden = true;
    if (!result.valid) {
      document.getElementById(fieldIds[Object.keys(result.errors)[0]]).focus();
      return;
    }
    setState('submitting');
    fieldset.disabled = true;
    submit.disabled = true;
    submit.textContent = '正在提交…';
    form.setAttribute('aria-busy', 'true');
    const controller = new AbortController();
    const timeout = window.setTimeout(() => controller.abort(), 15000);
    try {
      const response = await submitApplication({ ...result.fields, submissionId }, { signal: controller.signal, endpoint: config.recruitment.endpoint });
      const payload = await response.json().catch(() => null);
      if (!response.ok || payload?.ok !== true) {
        if (payload?.errors) setErrors(payload.errors);
        throw new Error(payload?.message || '暂时无法提交，请稍后重试。您也可以先将简历发送至以上邮箱。');
      }
      form.reset();
      form.hidden = true;
      success.hidden = false;
      setState('success');
      if (dialog.open) success.focus();
    } catch (failure) {
      setState('error');
      error.textContent = failure.name === 'AbortError' ? '提交超时，请稍后重试。' : failure.message;
      error.hidden = false;
    } finally {
      window.clearTimeout(timeout);
      fieldset.disabled = false;
      submit.disabled = false;
      submit.replaceChildren(...submitContent.map((node) => node.cloneNode(true)));
      form.removeAttribute('aria-busy');
    }
  });
  setState('idle');
}
