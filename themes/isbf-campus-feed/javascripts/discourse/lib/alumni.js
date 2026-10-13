export function alumniConfig(site) {
  const config = site?.isbf_alumni;
  return config?.enabled === true && Array.isArray(config.countries)
    ? config
    : null;
}

export function alumniRegions(config, country) {
  return country === "CN"
    ? config?.countries?.find((item) => item.code === country)?.regions || []
    : [];
}

export function alumniLocation(user) {
  return [
    user.country_name,
    user.country_code === "CN" ? user.region_name : null,
  ]
    .filter(Boolean)
    .join(" · ");
}
