const SELECT = "discourse/ui-kit/d-select";

/** Keeps the new select entrypoint while retaining the upstream import migration checks. */
export default function menuImports(rule) {
  return {
    ...rule,
    create(context) {
      // The pinned preset treats this now-public path as an obsolete alias.
      const sourceCode = new Proxy(context.sourceCode, {
        get(target, key) {
          if (key === "getAllComments") {
            return () =>
              target.getAllComments().map((comment) => ({
                ...comment,
                value: comment.value.replaceAll(
                  SELECT,
                  "discourse/ui-kit/z-select"
                ),
              }));
          }
          const value = Reflect.get(target, key, target);
          return typeof value === "function" ? value.bind(target) : value;
        },
      });
      const visitors = rule.create({
        sourceCode,
        report: (report) => context.report(report),
      });
      return {
        ...visitors,
        ImportDeclaration(node) {
          if (node.source.value !== SELECT) {
            visitors.ImportDeclaration?.(node);
          }
        },
        ExportNamedDeclaration(node) {
          if (node.source?.value !== SELECT) {
            visitors.ExportNamedDeclaration?.(node);
          }
        },
        "CallExpression[callee.name='importSync']"(node) {
          if (node.arguments[0]?.value !== SELECT) {
            visitors["CallExpression[callee.name='importSync']"]?.(node);
          }
        },
      };
    },
  };
}
