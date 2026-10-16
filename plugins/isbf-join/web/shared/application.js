export function validateApplication(value) {
  const input = value && typeof value === 'object' && !Array.isArray(value) ? value : {};
  const fields = Object.fromEntries(['name', 'studentId', 'phone'].map((key) => [key, typeof input[key] === 'string' ? input[key].trim() : '']));
  const errors = {};
  const safeText = (text) => !/[\u0000-\u001f\u007f]/u.test(text);
  if (!fields.name || fields.name.length > 60 || !safeText(fields.name)) errors.name = '请填写有效的姓名（最多 60 个字符）。';
  if (!fields.studentId || fields.studentId.length > 40 || !safeText(fields.studentId)) errors.studentId = '请填写有效的学号（最多 40 个字符）。';
  const digits = fields.phone.replace(/\D/g, '');
  if (!/^\+?[0-9 ()-]+$/.test(fields.phone) || digits.length < 7 || digits.length > 15 || fields.phone.length > 30) errors.phone = '请填写有效的手机号码，可包含国家区号。';
  return { fields, errors, valid: Object.keys(errors).length === 0 };
}
