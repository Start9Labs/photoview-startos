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
  await guardDurationAboveMinimum({ duration, minimumTime: 30000 });
  return checkWebUrl("http://photoview.embassy")(effects, duration).catch(catchError(effects))
};

const healthApi: T.ExpectedExports.health[""] = async (effects, duration) => {
  await guardDurationAboveMinimum({ duration, minimumTime: 30000 });

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

// Ensure the starting duration is past a minimum
export const guardDurationAboveMinimum = (
  input: { duration: number; minimumTime: number },
) => (input.duration <= input.minimumTime) ? errorCode(60, "Starting") : null;

export const catchError_ = (effects: T.Effects) => (e: unknown) => {
  if (isKnownError(e)) return e;
  effects.error(`Health check failed: ${e}`);
  return error("Error while running health check");
}
