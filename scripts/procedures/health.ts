import { types as T, checkWebUrl, catchError, ok, isKnownError, errorCode, error } from "../deps.ts";

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

const healthWeb: T.ExpectedExports.health[""] = async (effects, duration) => {
  const url = 'http://photoview.embassy'
  let errorValue
  if (
    // deno-lint-ignore no-cond-assign
    errorValue = guardDurationAboveMinimum({ duration, minimumTime: 20000 })
  ) return errorValue

  return await effects.fetch(url)
    .then((_) => ok)
    .catch((e) => {
      effects.warn(`Error while fetching URL: ${url}`);
      effects.error(JSON.stringify(e));
      effects.error(e.toString());
      return error(`Error while fetching URL: ${url}`);
    });
};

const healthApi: T.ExpectedExports.health[""] = async (effects, duration) => {
  let errorValue
  if (
    // deno-lint-ignore no-cond-assign
    errorValue = guardDurationAboveMinimum({ duration, minimumTime: 20000 })
  ) return errorValue

  return await effects.fetch("http://photoview.embassy:80/api/graphql", {
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

// Ensure the starting duration is past a minimum
export const guardDurationAboveMinimum = (
  input: { duration: number; minimumTime: number },
) => (input.duration <= input.minimumTime) ? errorCode(60, "Starting") : null;

export const catchError_ = (effects: T.Effects) => (e: unknown) => {
  if (isKnownError(e)) return e;
  effects.error(`Health check failed: ${e}`);
  return error("Error while running health check");
}
