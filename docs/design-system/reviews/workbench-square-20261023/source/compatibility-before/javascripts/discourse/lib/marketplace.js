export const MARKETPLACE_FIELDS = [
  "isbf_marketplace_price",
  "isbf_marketplace_images",
  "isbf_marketplace_home",
];

export function marketplaceConfig(site) {
  const config = site?.isbf_marketplace;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    config.private_images === true &&
    config.version === 1
    ? config
    : null;
}

export function isMarketplaceComposer(model) {
  const config = marketplaceConfig(model?.site);
  return Boolean(
    config &&
    Number(model.categoryId) === config.category_id &&
    (model.creatingTopic ||
      (model.editingPost && model.post?.post_number === 1)),
  );
}

export function marketplaceImageIds(value) {
  try {
    const ids = typeof value === "string" ? JSON.parse(value) : value;
    return Array.isArray(ids)
      ? [
          ...new Set(
            ids.filter(
              (id) =>
                typeof id === "string" &&
                /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(
                  id,
                ),
            ),
          ),
        ]
      : [];
  } catch {
    return [];
  }
}

export function marketplacePrice(cents) {
  return Number.isSafeInteger(cents) && cents >= 0
    ? `¥${(cents / 100).toFixed(2)}`
    : null;
}

export function validMarketplacePrice(value) {
  const text = String(value ?? "").trim();
  if (!/^(0|[1-9]\d*)(\.\d{1,2})?$/.test(text)) {
    return false;
  }
  const [whole, fraction = ""] = text.split(".");
  return Number.isSafeInteger(
    Number(whole) * 100 + Number(fraction.padEnd(2, "0")),
  );
}

export function marketplacePayload(model, field) {
  if (!isMarketplaceComposer(model)) {
    return;
  }
  if (field === MARKETPLACE_FIELDS[0]) {
    return String(model[field] ?? "").trim();
  }
  if (field === MARKETPLACE_FIELDS[1]) {
    return JSON.stringify(marketplaceImageIds(model[field]));
  }
  return model[field] === true;
}

export function restoreMarketplace(model, options = {}) {
  if (!isMarketplaceComposer(model)) {
    return;
  }
  const metadata =
    options.post?.isbf_marketplace ??
    model.post?.isbf_marketplace ??
    model.topic?.isbf_marketplace;
  const values = [
    metadata && marketplacePrice(metadata.price_cents)?.slice(1),
    metadata?.images?.map((image) => image.id),
    metadata?.show_on_home,
  ];
  MARKETPLACE_FIELDS.forEach((field, index) => {
    const value =
      options[field] ?? options.post?.[field] ?? model[field] ?? values[index];
    model.set(
      field,
      index === 0
        ? String(value ?? "")
        : index === 1
          ? JSON.stringify(marketplaceImageIds(value))
          : value === true,
    );
  });
  model.set("isbf_anonymous", false);
}

export function marketplaceQuery() {
  return {
    q: "isbf-marketplace:all order:created",
  };
}

export function marketplaceUploadMarkdown(upload, model) {
  if (
    !isMarketplaceComposer(model) ||
    !/^\/isbf\/marketplace\/images\/[a-f0-9-]{36}$/i.test(upload.url || "")
  ) {
    return;
  }
  const ids = marketplaceImageIds([upload.id]);
  if (!ids.length) {
    return;
  }
  model.set(
    "isbf_marketplace_images",
    JSON.stringify([
      ...new Set([
        ...marketplaceImageIds(model.isbf_marketplace_images),
        ...ids,
      ]),
    ]),
  );
  const name = String(
    upload.original_filename || upload.name || "image",
  ).replace(/[\[\]\\|\n\r]/g, "");
  return `![${name}](${upload.url})`;
}

export function marketplaceImageUrl(url) {
  return /^\/isbf\/marketplace\/images\/[a-f0-9-]{36}(?:\/thumbnail)?$/i.test(
    url || "",
  )
    ? url
    : null;
}

export function marketplaceDetailImages(metadata, renderedSources = []) {
  const shown = new Set(
    renderedSources.map((source) =>
      String(source)
        .match(
          /\/isbf\/marketplace\/images\/([a-f0-9-]{36})(?:\/thumbnail)?(?:$|[?#])/i,
        )?.[1]
        ?.toLowerCase(),
    ),
  );
  return (metadata?.images || [])
    .filter(
      (image) =>
        marketplaceImageIds([image.id]).length &&
        marketplaceImageUrl(image.url) &&
        !shown.has(image.id.toLowerCase()),
    )
    .map((image) => ({
      ...image,
      thumbnail: marketplaceImageUrl(image.thumbnail_url) || image.url,
    }));
}
