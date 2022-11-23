import { types as T, checkWebUrl, catchError } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  // deno-lint-ignore require-await
  async "interface"(effects, duration) {
    // Checks that the server is running and reachable via http
    return healthWeb(effects, duration);
  },
  // deno-lint-ignore require-await
  async "database"(effects, duration) {
    // Checks that the backend is reachable via graphQL
    return healthApi(effects, duration);
  },
};

// deno-lint-ignore require-await
const healthWeb: T.ExpectedExports.health[""] = async (effects, duration) => {
  return checkWebUrl("http://photoview.embassy")(effects, duration).catch(catchError(effects))
};

const healthApi: T.ExpectedExports.health[""] = async (effects, duration) => {
  await guardDurationAboveMinimum({ duration, minimumTime: 15000 });

  return effects.fetch("http://photoview.embassy:80/api/graphql", {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({"operationName":"CheckInitialSetup","variables":{},"query":"query CheckInitialSetup { siteInfo { initialSetup }}"})
  })
    .then((_) => ok)
    .catch((e) => {
      effects.error(`${e}`)
      return error(`The Photoview API is unreachable`)
    });
};

// *** HELPER FUNCTIONS *** //

// Ensure the starting duration is pass a minimum
const guardDurationAboveMinimum = (
  input: { duration: number; minimumTime: number },
) =>
  (input.duration <= input.minimumTime)
    ? Promise.reject(errorCode(60, "Starting"))
    : null;

const errorCode = (code: number, error: string) => ({
  "error-code": [code, error] as const,
});
const error = (error: string) => ({ error });
const ok = { result: null };
