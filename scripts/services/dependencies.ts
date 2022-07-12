import { matches, types as T } from "../deps.ts";

const { shape, arrayOf, string, boolean } = matches;

const matchLndConfig = shape({
  nodes: shape({
    type: string,
  }),
});

type Check = {
  currentError(config: T.Config): string | void;
  fix(config: T.Config): T.Config;
};

export const dependencies: T.ExpectedExports.dependencies = {
  lnd: {
    // deno-lint-ignore require-await
    async check(effects, configInput) {
      effects.info("check lnd");
      const config = matchLndConfig.unsafeCast(configInput);
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(effects, configInput) {
      effects.info("autoconfigure lnd");
      const config = matchLndConfig.unsafeCast(configInput);
      return { result: config };
    },
  },
};