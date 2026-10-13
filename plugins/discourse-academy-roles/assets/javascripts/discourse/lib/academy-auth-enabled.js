export default function academyAuthEnabled(_args, _component, owner) {
  const settings = owner.lookup("service:site-settings");
  return settings.academy_roles_enabled && settings.academy_auth_page_enabled;
}
