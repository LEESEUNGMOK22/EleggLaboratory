import { createInitialState, reduce } from "./state-machine.js";

export function createStore() {
  let state = createInitialState();
  const listeners = new Set();

  return {
    getState() { return state; },
    dispatch(action) {
      state = reduce(state, action);
      listeners.forEach((fn) => fn(state, action));
      return action;
    },
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    reset() {
      state = createInitialState();
      listeners.forEach((fn) => fn(state, { type: "RESET" }));
    }
  };
}
